if kubectl get namespaces -o json | jq -r ".items[].metadata.name" | grep cert-manager;then
  echo 'Cert Manager is already installed'
else
  kubectl create namespace cert-manager
fi
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager  --version v1.0.2 --set installCRDs=true --wait --timeout=10m0s
imgpkg pull -b $1 --registry-verify-certs=false -o ./bundle
cd bundle/
kubectl create namespace rabbitmq-system
ytt -f manifests/cluster-operator.yml -f manifests/messaging-topology-operator-with-certmanager.yaml | kbld -f .imgpkg/images.yml -f config/ -f- | kapp -y deploy -a rabbitmq-operator -f -
