# Setting Cilium as your CNI
## Instructions
1. Create the following directory if it does not exist:
~/.config/tanzu/tkg/providers/ytt/04_user_customizations
2. move the files in this folder to the folder you just created / validated exists
3. in your cluster config file you can add the following variables:
* INSTALL_CILIUM: true
* INSTALL_CILIUM_CLI: true (optional but suggested for debugging)
* CNI: none (Required as we are not installing a tanzu managed CNI)
4. This will install Cilium via the cilium operator with default settings automatically when you create a cluster
