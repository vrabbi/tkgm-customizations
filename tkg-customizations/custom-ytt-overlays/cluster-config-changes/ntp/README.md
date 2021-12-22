# Setting NTP servers to be configured on nodes
## Instructions
1. Create the following directory if it does not exist:
~/.tanzu/tkg/providers/ytt/04_user_customizations
2. move the 2 files in this folder to the folder you just created / validated exists
3. in your cluster config file you can add the following variables:
* NTP_SERVERS: "x.x.x.x,y.y.y.y" (Comma seperated list of NTP servers)
4. this will configure the NTP servers on the k8s nodes at provisioning time
