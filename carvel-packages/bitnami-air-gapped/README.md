# Bitnami Helm Chart Conversion to Packages - with Air Gapped Environment Support!!!!!!!
One of the key strengths of the Carvel Packaging is that it is not only for YTT and KAPP rather can also manage things like helm  
In this Folder i have an example script that will generate a package repository and all the needed files within it to install any bitnami helm chart as a package install object  
This will also enable you to utilize these charts in an air gapped environment  

# Options for running the tool
1. Run the script on a linux machine directly
* this gives the most flexibility but requires a bunch of pre reqs on your system which are mentioned bellow in the Script based execution section
2. Utilize the Docker image ghcr.io/vrabbi/bitnami-airgaping-tool:0.1.2
* this allows for a very simple process to generate such a repo and can also be run on MAC


## Running the container
1. you will need docker installed on your machine
2. login to the destination oci registry with docker CLI on your machine - the docker config.json with creds is mapped into the container to ease passing in credentials
``` bash
docker login <REGISTRY FQDN>
```  
2. make sure that PWD and HOME env variables are set
``` bash
echo $PWD
echo $HOME
```  
3. create a sub folder in your current directory called output
``` bash
mkdir output
```  
4. Create an alias for running the container easily with all needed mounts
``` bash
alias generate-bitnami-packages="docker run -i -v $HOME/.docker/config.json:/root/.docker/config.json -v $PWD/output:/output ghcr.io/vrabbi/bitnami-airgaping-tool:0.1.3"
```  
5. OPTIONAL - if you want to supply a list of charts to package instead of the entire repo create a file named chart-list.txt in the current directory and update the alias from step 4
``` bash
touch chart-list.txt
alias generate-bitnami-packages="docker run -i -v $HOME/.docker/config.json:/root/.docker/config.json -v $PWD/output:/output -v $PWD/chart-list.txt:/app/chart-list.txt ghcr.io/vrabbi/bitnami-airgaping-tool:0.1.3"
```
* now fill in the chart names in the format \<REPO NAME\>/\<CHART NAME\> one per line
* when running the tool you must pass the flag "--chart-list-file-path" with the value "/app/chart-list.txt"
6. run the following to see detailed help menu on how to run the tool
``` bash
generate-bitnami-packages --help
```  
7. BASH Autocompletion - run the following commands to get bash auto completion for flags
``` bash
source <(generate-bitnami-packages --bash-completion)
```  
8. The outputted manifests will be available in the output directory you created above
 

## Running the script
in order to run the script you will need to have pre installed:  
1. jq - https://stedolan.github.io/jq/download/  
2. yq - https://github.com/kislyuk/yq  
3. readme-generator - https://github.com/bitnami-labs/readme-generator-for-helm  
4. helm - helm v3+ - https://github.com/helm/helm  
5. json2yml - https://www.npmjs.com/package/json2yaml  
6. kbld and imgpkg - https://carvel.dev

Once this is all installed run the following to see the commandline flags:  
``` bash
./generate-bitnami-packages.sh --help
```  

Example Usage:  
```bash
./generate-packages-and-repo.sh --registry harbor.example.com --repository bitnami --package-repository-name bitnami-air-gapped-repo --package-repository-tag 1.0.0 --number-of-chart-versions 4   
```  
  
Parameterized instructions for using the generated repo will be printed at the end of the script execution.  
  
# General Usage Instructions
## Installing the package repo in a non air gapped environment
You can choose either of the following options:  
  
1. Add as a global package to your tanzu cluster with default settings:  
```bash
    tanzu package repository add bitnami-air-gapped-repo --url harbor.example.com/bitnami/bitnami-air-gapped-repo:0.1.0 --namespace tanzu-package-repo-global
```  
2. Add as a global package to your tanzu cluster with custom sync interval:  
```bash
    kubectl apply -n tanzu-package-repo-global -f /tmp/carvel-bitnami-packages/package-repository-manifest.yaml  
```  
  
  
## Air Gapped Instructions  
  
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
** edit the file at the path /tmp/carvel-bitnami-packages/package-repository-manifest.yaml and change the image reference to your airgapped environment  
** add the repo to your cluster  
```bash
    kubectl apply -n tanzu-package-repo-global -f /tmp/carvel-bitnami-packages/package-repository-manifest.yaml
```

