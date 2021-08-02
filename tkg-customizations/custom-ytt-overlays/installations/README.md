# Installation
## Pre Reqs
In order to gain these capabilities make sure you have:
1. Created the docker image based on this repo
2. update the variable TKG_HELPER_IMAGE_REF and any other relevant variables in the custom_variables.yaml file in this repo and added these to your config_default.yaml file
3. if your custom image is in an internal CA signed registry, make sure you have followed the instructions in the relevant folder of this repo on how to make your clusters trust the CA certificate

## Procedure
1. Create the following folder if it does not already exist
~/.tanzu/tkg/providers/ytt/04_user_customizations
2. copy all files in this repo to that directory

## Imprtant Note
the values in the custom_variables.yaml file have all installations off by default. you can change the values there or simply set them to the appropriate values in your cluster manifests. 

Each addon requires different variables to be set. please look at the comments in the custom_variables.yaml file which explain what is needed for each customization
