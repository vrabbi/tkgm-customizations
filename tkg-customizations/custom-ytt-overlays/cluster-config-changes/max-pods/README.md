# Setting Maximum Pods per Core on worker nodes and on control plane nodes
## Instructions
1. Create the following directory if it does not exist:
~/.tanzu/tkg/providers/ytt/04_user_customizations
2. move the 2 files in this folder to the folder you just created / validated exists
3. in your cluster config file you can add the following variables:
* CONTROL_PLANE_MAX_PODS_PER_CORE
* WORKER_MAX_PODS_PER_CORE
4. this will take at runtime your CPU count config on MachineDeployments and KubeadmControlPlane objects and do the math to set the Max Pods value for the kubelet configuration
