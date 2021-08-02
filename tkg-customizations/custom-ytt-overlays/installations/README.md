# Installation
## Pre Reqs
In order to gain these capabilities make sure you have:
1. Created the docker image based on this repo
2. Note: Each installation in this folder has 2 files <CUSTOMIZATION>.yaml and <CUSTOMIZATION>-default-values.yaml
3. Update the variable TKG_HELPER_IMAGE_REF in the install-tkg-extensions-default-values.yaml file no matter which of these extensions you plan to install
4. Update if you need any of the default values for the different customizations in the relevant *-default-values.yaml files
5. If your custom image is in an internal CA signed registry, make sure you have followed the instructions in the relevant folder of this repo on how to make your clusters trust the CA certificate

## Procedure
1. Create the following folder if it does not already exist
~/.tanzu/tkg/providers/ytt/04_user_customizations
2. copy all files in this repo to that directory

## Imprtant Note
the values in the provided files have all customizations off by default. you can change the values in the relvant *-default-values.yaml files or simply set them to the appropriate values in your cluster manifests. 

Each addon requires different variables to be set. please look at the relevant *-default-values.yaml file for each customization which explains what is needed and possible to configure
