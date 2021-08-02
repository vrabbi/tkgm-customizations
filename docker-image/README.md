# Disclaimer
This folder is not complete and will not run as is!!!!!

# Instructions
## Download the needed files not in the repo
while i have included many files in the repo including the scripts used to install the solutions, the actual packages from VMware are not added here as they should be downloaded through the official websites and mediums of VMware.
### Needed files
For TKGm Extensions automation:
1. TKGm Extensions manifest bundle - this can be downloaded from MyVMware. (just place the tar file in the same folder as this README.)
2. Download from MyVMware the file kubectl-linux-v1.20.5-vmware.1.gz and place it in this folder
3. For Velero - you must download from MyVMware the file velero-linux-v1.5.3_vmware.1.gz and place it in this folder

For Tanzu Advanced Operators:
1. Tanzu Postgres
  * you must download from TanzuNet / PivNet the file postgres-for-kubernetes-v1.1.0.tar.gz and place it in this folder
  * you must also pre load the 2 docker images as per the docs to an image registry (eg Harbor)
2. Tanzu MySQL
  * you must download from TanzuNet / PivNet the file tanzu-mysql-deployment-templates-1.0.0.tgz and place it in this folder
  * The Tanzu MySQL deployment here pulls the images from the pivotal registry directly so this will need adaptation to work in air gapped environments
3. Tanzu RabbitMQ
  * You must have already pushed the RabbitMQ imgpkg bundle to your own registry as per the docs
  * no additional files are needed for the docker image creation for RabbitMQ

For Tanzu Mission Control
1. you must download the TMC CLI from the TMC portal and place it in this folder with the file name tmc.

## 2. Build the image
run this from within the urrent directory
```bash
# Example docker build . -t harbor.terasky.demo/library/tkg-crs:v1.3.1
docker build . -t <IMAGE NAME : TAG>
docker push <IMAGE NAME : TAG>
```
