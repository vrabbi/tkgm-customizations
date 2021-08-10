# This adds chartmuseum to your harbor deployment in TKG

## instructions
1. Follow steps 1-6 of the regular docs at https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-extensions-harbor-registry.html
2. create an additional secret with our additional chartmuseum config which can be found in the harbor-chartmuseum-addition.yaml file.
```bash
kubectl create secret generic harbor-chartmuseum-addition --from-file=chartmuseum.yaml=harbor-chartmuseum-addition.yaml -n tanzu-system-registry
``` 
3. add refernece to the secret we created in the app manifest and deploy it. this can be done in 1 of 2 ways:
* Use the file habor-app.yaml in this repo
* Edit the harbor-extension.yaml file from the tkg-extensions bundle at the path extensions/registry/harbor/harbor-extension.yaml
 
option 1 - Using custom app manifest: 
```bash
kubectl apply -f habor-app.yaml
``` 

option 2 - Update the official manifest: 
* after line 25 add the following stanza:
```bash
- secretRef:                         
    name: harbor-chartmuseum-addition
```
* make sure the stanza is inline with the original secretRef for the harbor-data-values but is bellow it.
* deploy the app
```bash
kubectl apply -f registry/harbor/harbor-extension.yaml
```
