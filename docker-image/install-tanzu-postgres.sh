#! /bin/bash
if kubectl get namespaces -o json | jq -r ".items[].metadata.name" | grep cert-manager;then
  echo 'Cert Manager is already installed'
else
  kubectl create namespace cert-manager
fi
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager  --version v1.0.2 --set installCRDs=true --wait --timeout=10m0s
cd ./postgres-for-kubernetes-v*
kubectl create secret docker-registry regsecret --docker-server=$1 --docker-username=$2 --docker-password=$3 --namespace default
helm upgrade --install postgres-operator operator/ --set operatorImageRepository=$4 --set postgresImageRepository=$5 --namespace default
kubectl wait --for=condition=Available deployment/postgres-operator --timeout=10m0s --namespace default
