# TKG Helper Scripts
This repo contains scripts that can help manage a TKG Environment

## Content:
1. generate-tkg-kubeconfigs.sh - this script will generate both per cluster and also a merged kubeconfig in 3 different formats:
a. admin kubeconfig
b. pinniped kubeconfig for use with a browser
c. pinniped kubeconfig for use without a browser
2. generate-tkg-terraform-file.sh - this script will generate a terraform config for deploying your TKG clusters
a. run this script with 1 variable which is the path to the cluster config file
b. you must have yq,jq and tfk8s installed on your machine
c. the script will output all needed files in a directory named with the new clusters name

