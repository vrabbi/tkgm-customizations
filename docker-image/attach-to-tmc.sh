export TMC_API_TOKEN=$1
tmc login -name tmc -c
tmc managementcluster provisioner tanzukubernetescluster manage $2 --cluster-group $3 -m $4 -p $5
