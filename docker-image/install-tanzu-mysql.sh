#! /bin/bash
if kubectl get namespaces -o json | jq -r ".items[].metadata.name" | grep cert-manager;then
  echo 'Cert Manager is already installed'
else
  kubectl create namespace cert-manager
fi
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager  --version v1.0.2 --set installCRDs=true --wait --timeout=10m0s
export HELM_EXPERIMENTAL_OCI=1
helm registry login registry.pivotal.io -u $1 -p $2 --insecure
helm chart pull registry.pivotal.io/tanzu-mysql-for-kubernetes/tanzu-mysql-operator-chart:1.0.0
kubectl create namespace tanzu-mysql-for-kubernetes-system
kubectl create secret docker-registry tanzu-mysql-image-registry --docker-server=https://registry.pivotal.io/ --docker-username=$1 --docker-password=$2 -n tanzu-mysql-for-kubernetes-system
helm chart export registry.pivotal.io/tanzu-mysql-for-kubernetes/tanzu-mysql-operator-chart:1.0.0
helm upgrade --install tanzu-sql-with-mysql-operator ./tanzu-sql-with-mysql-operator/ -n tanzu-mysql-for-kubernetes-system
kubectl wait --for=condition=Available deployment/tanzu-sql-with-mysql-operator --timeout=10m0s -n tanzu-mysql-for-kubernetes-system
