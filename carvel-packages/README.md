# Examples for building custom Carvel Packages and adding them to a package repo
## The URLs these packages and repo are published at are:
1. vrabbi/octant-turnkey:0.24.0
2. vrabbi/openvscode:0.0.1
3. vrabbi/k8s-tools-repo:0.1.0
4. vrabbi/tkg-extensions-package:1.4.0

## Packages
In this repo we have 3 examples of packages: 
1. octant - (based on the octant-turnkey github repo which provides a helm chart to deploy octant)
2. open VS Code - (A Web base VS Code editor which can be run on K8s)
3. TKG Extensions package - view the readme in the relevant folder for more information on this  

These packages are just examples of what you can do. 

## Package Repository
In this repo we have an example of adding the 2 packages mentioned above into a package repo. 
This Package repo can then be added to clusters and will allow deployment of either of the above packages.

## Tanzu Integration
Once you have a published package repository you can easily integrate it with TKGm by adding the repository to your clusters using the tanzu CLI:
``` bash
tanzu package repository add <REPO NAME> --url <REPO URL> --namespace <NAMESPACE> --create-namespace
```  
Once the repo has been added wait a minute or 2 untill it has fully reconciled which can be verified via the command:
``` bash
kubectl get packagerepository <REPO NAME> -n <NAMESPACE>
```  
Once the Repo has reconciled you can view the packages available at any time via the command:
``` bash
tanzu package available list -n <NAMESPACE>
```  
You can view the versions available for a specific package by running:
``` bash
tanzu package available list <PACKAGE NAME> -n <NAMESPACE>
```  
Once you have the package name and version you can retrieve the values schema for the package by running:
``` bash
tanzu package available get <PACKAGE NAME>/<VERSION> -n <NAMESPACE> --values-schema
```  
If you want to get just the keys for easy rendering of a values file you can use yq as such:
``` bash
tanzu package available get <PACKAGE NAME>/<VERSION> -n <NAMESPACE> --values-schema -o yaml | yq '.[].key' -r
```  
