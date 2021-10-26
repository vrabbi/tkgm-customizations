# Bitnami Helm Chart Conversion to Packages - with Air Gapped Environment Support!!!!!!!
One of the key strengths of the Carvel Packaging is that it is not only for YTT and KAPP rather can also manage things like helm  
In this Folder i have an example script that will generate a package repository and all the needed files within it to install any bitnami helm chart as a package install object  
This will also enable you to utilize these charts in an air gapped environment  

## Running the script
in order to run the script you will need to have pre installed:  
1. jq - https://stedolan.github.io/jq/download/  
2. yq - https://github.com/kislyuk/yq  
3. readme-generator - https://github.com/bitnami-labs/readme-generator-for-helm  
4. helm - helm v3+ - https://github.com/helm/helm  
5. json2yml - https://www.npmjs.com/package/json2yaml  

Once this is all installed run the following to see the commandline flags:  
``` bash
./generate-packages-and-repo.sh --help
```  

Example Usage:  
```bash
./generate-packages-and-repo.sh --registry harbor.example.com --repository bitnami --package-repository-name bitnami-air-gapped-repo --package-repository-tag 1.0.0 --number-of-chart-versions 4   
```  
  
Parameterized instructions for using the generated repo will be printed at the end of the script execution.  
  
## General Usage Instructions
### Installing the package repo in a non air gapped environment
You can choose either of the following options:  
  
1. Add as a global package to your tanzu cluster with default settings:  
```bash
    tanzu package repository add bitnami-air-gapped-repo --url harbor.example.com/bitnami/bitnami-air-gapped-repo:0.1.0 --namespace tanzu-package-repo-global
```  
2. Add as a global package to your tanzu cluster with custom sync interval:  
```bash
    kubectl apply -n tanzu-package-repo-global -f /tmp/carvel-bitnami-packages/package-repository-manifest.yaml  
```  
  
  
### Air Gapped Instructions  
  
1. Run the following command to copy all packages and images into a tar ball on your machine:  
```bash
    imgpkg copy -b harbor.example.com/bitnami/bitnami-air-gapped-repo:0.1.0 --to-tar /tmp/my-repo.tar --registry-verify-certs=false  
```  
2. Import the Tar file to the airgapped environment  
3. Run the following to import the artifacts to an OCI registry in your air gapped environment:  
```bash
    imgpkg copy --tar /tmp/my-repo.tar --to-repo <AIR GAPPED REGISTRY>/<AIR GAPPED REPO> --registry-verify-certs=false  
```
4. Add the repo to your cluster with either of the following options:  
*  Add as a global package to your tanzu cluster with default settings:  
```bash
    tanzu package repository add bitnami-airgapped-chart-repo --url <AIR GAPPED REGISTRY>/<AIR GAPPED REPO>:<PACKAGE REPO TAG> --namespace tanzu-package-repo-global
```  
* Add as a global package to your tanzu cluster with custom sync interval:  
- edit the file at the path /tmp/carvel-bitnami-packages/package-repository-manifest.yaml and change the image reference to your airgapped environment  
- add the repo to your cluster  
```bash
    kubectl apply -n tanzu-package-repo-global -f /tmp/carvel-bitnami-packages/package-repository-manifest.yaml
```

