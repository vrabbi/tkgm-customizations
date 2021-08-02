This folder contains 3 sub folders

## cluster-plans
currently one additional plan has been created named multimd.
in order to utilize the multi machine deployment customization:
1. Copy the file in this folder with its exact name to the following path
~/.tanzu/tkg/providers/infrastructure-vsphere/v0.7.7/cluster-template-definition-multimd.yaml
2. follow the instructions under the custom-ytt-overlays/multi-md/ folder for the next steps

## cluster-manifests
This folder contains example manifests of clusters utilizing this repos customizations

## custom-ytt-overlays
This folder contains the custom YTT templates which are utilized in this repo to automate the different customizations
