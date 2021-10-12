# Bitnami Helm Chart Conversion to Packages
One of the key strengths of the Carvel Packaging is that it is not only for YTT and KAPP rather can also manage things like helm  
In this Folder i have an example script that will generate a package repository and all the needed files within it to install any bitnami helm chart as a package install object  

## Using pore generated manifests
* In this repo i have added pre generated manifests you can use.  
* these may not be up to date with the latest chart version depending on when you are using this
* if using this method and not generating the manifests your self you can skip ahead to step 2 under "building and publishing the repo" namely the kbld step.  

## Running the script
in order to run the script you will need to have pre installed:  
1. YQ
2. readme-generator - https://github.com/bitnami-labs/readme-generator-for-helm
3. helm  

once this is all installed run:  
``` bash
./generate-packages-and-repo.sh
```  
The files will be generated at the path: /tmp/carvel-bitnami-packages/

## building and publishing the repo
1. go to the parent folder of the generated folder path
``` bash
cd /tmp/
```  
2. generate the .imgpkg folder and run kbld to create the lock file
``` bash
mkdir carvel-bitnami-packages/.imgpkg
kbld -f carvel-bitnami-packages/packages/ --imgpkg-lock-output carvel-bitnami-packages/.imgpkg/images.yml
```  
3. push the repo bundle to the destination repository
``` bash
imgpkg push -b ${REPO_HOST}/packages/bitnami-charts-repo:1.0.0 -f carvel-bitnami-packages
```  
4. Generate the Package Repo manifest
``` bash
cat > repo.yml << EOF
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  name: bitnami-charts-repo
spec:
  fetch:
    imgpkgBundle:
      image: ${REPO_HOST}/packages/bitnami-charts-repo:1.0.0
EOF
```  
5. in TCE (0.9.1+) or TKGm (1.4+) install the package via the Tanzu CLI globally
``` bash
tanzu package repository add bitnami-charts --url ghcr.io/vrabbi/bitnami-charts-repo:1.0.0 -n tanzu-package-repo-global --create-namespace
```
## Usage Notes
* the script generates the OpenAPIv3 Schema for the entire Helm Values file on the package for ease of discovery of allowed values.  
* the same values and in the same format as can be passed to helm can be done now with the packages.  
