# Installing Tanzu Data Services on TKGM Clusters
## Problem Statement
In TKGm, the version of cert-manager which is deployed for the TKGm Extensions is version 0.16.1 
While this version works, it does not include the needed API Version (v1) of Cert Manager which are needed for the Tanzu Data Services including Tanzu RabbitMQ, Tanzu PostgreSQL and Tanzu MySQL. 
TKGm Extensions create Certificates using the v1beta1 API version which luckily is supported along side the v1 API version in Cert Manager 1.5 which is the latest version at this point.

## Mitigation strategy
The mitigation starategy depends on the state of your TKGm Clusters and can be split into 2 categories:
1. You have not installed TKGm Extensions yet in the cluster
2. You have already installed TKGm Extensions and as such have installed Cert Manager 0.16.1

### Mitigation when no TKGm Extensions have been installed yet
#### TLDR
Deploy version 1.2 or later (1.5 is the current latest version and still supports the v1beta1 API) of Cert Manager and not the TKGm Extension bundle supplied version of Cert Manager

#### Key Consideration
VMware do not supply signed binaries of Cert Manager except for version 0.16.1 at this point. 
In order to install Cert Manager in an air gapped environment or an environment behind a proxy you have 2 options:
1. open up access to pull images from quay.io from your K8s clusters
2. Import the newer Cert Manager images into a local Registry such as the TKGm Harbor Extension and pull the images from there.

#### With Access To quay.io
```bash
kbld -f https://github.com/jetstack/cert-manager/releases/download/v1.5.0/cert-manager.yaml | kapp deploy -y -a cert-manager -f-
```
#### Without Access To quay.io
1. Extract the needed images from the default manifest 
```bash
wget https://github.com/jetstack/cert-manager/releases/download/v1.5.0/cert-manager.yaml
cat cert-manager.yaml | yq -N e '..|.image? | select(.)' - | sort -u > images.yaml
``` 
2. for each image listed in the images.yaml
```bash
docker pull <IMAGE>:<TAG>
docker tag <IMAGE> <NEW IMAGE LOCATION IN INTERNAL REGISTRY>:<TAG>
docker push <NEW IMAGE LOCATION IN INTERNAL REGISTRY>:<TAG>
``` 
3. update the cert-manager.yaml file with the new image references
```bash
sed -i 's|quay.io/jetstack|<NEW REGISTRY PATH WHERE IMAGES ARE LOCATED>|g' cert-manager.yaml
``` 
4. Deploy Cert Manager
```bash
kbld -f cert-manager.yaml | kapp deploy -y -a cert-manager -f-
``` 
### Mitigation When Cert Manager 0.16.1 is already installed as part of the TKGm Extensions
VMware do not supply signed binaries of Cert Manager except for version 0.16.1 at this point.
In order to install Cert Manager in an air gapped environment or an environment behind a proxy you have 2 options:
1. open up access to pull images from quay.io from your K8s clusters
2. Import the newer Cert Manager images into a local Registry such as the TKGm Harbor Extension and pull the images from there.

#### With Access To quay.io
```bash
kbld -f https://github.com/jetstack/cert-manager/releases/download/v1.5.0/cert-manager.yaml | kubectl apply -f -
```
#### Without Access To quay.io
1. Extract the needed images from the default manifest
```bash
wget https://github.com/jetstack/cert-manager/releases/download/v1.5.0/cert-manager.yaml
cat cert-manager.yaml | yq -N e '..|.image? | select(.)' - | sort -u > images.yaml
```
2. for each image listed in the images.yaml
```bash
docker pull <IMAGE>:<TAG>
docker tag <IMAGE> <NEW IMAGE LOCATION IN INTERNAL REGISTRY>:<TAG>
docker push <NEW IMAGE LOCATION IN INTERNAL REGISTRY>:<TAG>
```
3. update the cert-manager.yaml file with the new image references
```bash
sed -i 's|quay.io/jetstack|<NEW REGISTRY PATH WHERE IMAGES ARE LOCATED>|g' cert-manager.yaml
```
4. Deploy Cert Manager
```bash
kbld -f cert-manager.yaml | kubectl apply -f -
```

