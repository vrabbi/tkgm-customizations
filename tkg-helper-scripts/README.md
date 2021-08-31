# TKG Helper Scripts
This repo contains scripts that can help manage a TKG Environment

## Content:
1. generate-tkg-kubeconfigs.sh - this script will generate both per cluster and also a merged kubeconfig in 3 different formats:
  * admin kubeconfig
  * pinniped kubeconfig for use with a browser
  * pinniped kubeconfig for use without a browser
2. generate-tkg-terraform-file.sh - this script will generate a terraform config for deploying your TKG clusters
  * run this script with 1 variable which is the path to the cluster config file
  * you must have yq,jq and tfk8s installed on your machine
  * the script will output all needed files in a directory named with the new clusters name

