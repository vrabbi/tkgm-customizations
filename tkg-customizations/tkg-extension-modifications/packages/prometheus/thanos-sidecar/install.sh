#!/bin/bash

# Retrieve the TKC cluster name from input
TKC_CLUSTER_NAME=$1

# Update the values.yaml for the prometheus configuration with the cluster name
# this is needed as we are adding external labels to the prometheus instance as is required by thanos to distinguish each prometheus instance
sed "s/##TKC_CLUSTER_NAME##/$TKC_CLUSTER_NAME-tanzu-prometheus/g" tanzu-prometheus-values-template.yaml > tanzu-prometheus-values.yaml

# get the latest version of the prometheus package so as not to hard code a specific version
PKG_NAME=prometheus.tanzu.vmware.com
PKG_VERSION=$(tanzu package available list "$PKG_NAME" -n tanzu-package-repo-global -o json | jq -r ".[0].version")

# Create the secrets holding the overlay files for Thanos Sidecar injection
kubectl create namespace tkg-packages --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic thanos-sidecar-overlay -n tkg-packages --from-file=thanos-sidecar-overlay.yaml -o yaml --dry-run=client | kubectl apply -f -

# Install the prometheus Package
tanzu package install prometheus --package-name "$PKG_NAME" --version "$PKG_VERSION" --values-file tanzu-prometheus-values.yaml --namespace tkg-packages --create-namespace --wait=false

# we need to annotate the packageinstall object just created with the ovwerlay files so as to apply them
kubectl annotate packageinstalls prometheus ext.packaging.carvel.dev/ytt-paths-from-secret-name.0=thanos-sidecar-overlay -n tkg-packages

# we need to wait for the package to create the tanzu-system-monitoring namespace in order to proceed
while : ; do
  kubectl get ns tanzu-system-monitoring && break
  sleep 5
done

# our overlay for thanos requires a recreation of the prometheus-server as we are adding another container. this spins up a new replicaset but as the old replicaset still has the PVC attached we need to delete the old replicaset in order to allow the new one to come up. for this reason we are waiting until 2 replicasets are found for the prometheus server and then proceeding to delete the old one
COUNT=0
while [ $COUNT -le 1 ]
do
  COUNT=`kubectl get replicasets.apps -n tanzu-system-monitoring -l component=server --no-headers | wc -l`
  sleep 10
done

# Retrieving the name of the oldest prometheus server replica set which is to be deleted
RS_NAME=`kubectl get replicasets.apps -n tanzu-system-monitoring -l component=server --sort-by=.metadata.creationTimestamp --no-headers -o json | jq -r .items[0].metadata.name`

# Deleting the replicaset
kubectl delete replicaset -n tanzu-system-monitoring $RS_NAME

# Waiting for the package to report successful reconciliation
kubectl wait --for=condition=ReconcileSucceeded pkgi/prometheus -n tkg-packages --timeout=10m
