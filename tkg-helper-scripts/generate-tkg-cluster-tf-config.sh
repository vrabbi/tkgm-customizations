TEMP_CLUSTER_NAME=`cat $1 | yq eval -j - | jq -r '.CLUSTER_NAME'`
mkdir $TEMP_CLUSTER_NAME
cd $TEMP_CLUSTER_NAME
tanzu management-cluster kubeconfig get --admin --export-file ./temp-mgmt-kc
TEMP_CA_DATA=`KUBECONFIG=./temp-mgmt-kc kubectl config view --raw | yq eval -j - | jq -r '.clusters[0].cluster."certificate-authority-data"'`
TEMP_KEY_DATA=`KUBECONFIG=./temp-mgmt-kc kubectl config view --raw | yq eval -j - | jq -r '.users[0].user."client-key-data"'`
TEMP_CERT_DATA=`KUBECONFIG=./temp-mgmt-kc kubectl config view --raw | yq eval -j - | jq -r '.users[0].user."client-certificate-data"'`
TEMP_URL=`KUBECONFIG=./temp-mgmt-kc kubectl config view --raw | yq eval -j - | jq -r '.clusters[0].cluster.server'`
cat << EOF > providers.tf
provider "kubernetes" {
  experiments {
    manifest_resource = true
  }
  host = var.management_cluster_url

  client_certificate     = base64decode(var.management_cluster_cert)
  client_key             = base64decode(var.management_cluster_key)
  cluster_ca_certificate = base64decode(var.management_cluster_ca)
}
EOF
cat << EOF > variables.tf
variable "management_cluster_url" {
  type = string
}

variable "management_cluster_cert" {
  type = string
}

variable "management_cluster_key" {
  type = string
}

variable "management_cluster_ca" {
  type = string
}
EOF
cat << EOF > terraform.tfvars
management_cluster_cert = "$TEMP_CERT_DATA"
management_cluster_key  = "$TEMP_KEY_DATA"
management_cluster_ca   = "$TEMP_CA_DATA"
management_cluster_url  = "$TEMP_URL"
EOF

tanzu cluster create -d -f $1 > temp-cluster.yaml
tfk8s -f temp-cluster.yaml -o ./tkg-cluster.tf
rm -f ./temp-mgmt-kc
rm -f temp-cluster.yaml

