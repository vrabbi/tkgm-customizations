# Installation Options
1. Directly as a package
2. Using a package Repo

## Installing as a direct Package
1. apply the needed files
``` bash
kubectl apply -n tanzu-package-repo-global -f metadata.yaml
kubectl apply -n tanzu-package-repo-global -f package.yaml
```  
2. Create a values file with your specific values
``` bash
cat <<EOF > values.yaml
vip_range: 10.100.100.100-10.100.100.150
EOF
```
3. Install the Package
``` bash
tanzu package install kubevip -p kubevip.terasky.com -v 0.3.9 -f values.yaml
```  

## Using a Package Repo
This package is in the K8s-Tools demo repo in this git repository under tkgm-customizations/carvel-packages/demo-package-repo

