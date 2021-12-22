# Setting KubeProxy to work in IPVS mode
## Instructions
1. Create the following directory if it does not exist:
~/.tanzu/tkg/providers/ytt/04_user_customizations
2. move the 2 files in this folder to the folder you just created / validated exists
3. in your cluster config file you can add the following variable:
* ENABLE_IPVS: true
4. this will configure the kernel parameters on all nodes and set kubeproxy to use IPVS cluster wide

