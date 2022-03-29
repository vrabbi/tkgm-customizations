# Mixed Windows and Linux Workload Clusters (TKGm 1.5.1+)
In TKGm 1.5.1 we now have windows cluster support. the issue is that it only supports Windows only clusters and doesnt support mixed clusters.  
To support Mixed Clusters we need to make a few changes to the YTT files included in TKGm and also add a few additional Files:

# File Changes
## Enable CSI (Disabled on widows clusters)
1. Edit the file ~/.config/tanzu/tkg/providers/ytt/02_addons/csi/csi_secret.yaml
2. Replace the if statement to support our mixed cluster scenario
```bash
# LINE TO REPLACE:

#@ if data.values.PROVIDER_TYPE == "vsphere" and not data.values.IS_WINDOWS_WORKLOAD_CLUSTER:

# REPLACE WITH

#@ if data.values.PROVIDER_TYPE == "vsphere":
#@ if data.values.IS_WINDOWS_WORKLOAD_CLUSTER and data.values.IS_MIXED_CLUSTER or not data.values.IS_WINDOWS_WORKLOAD_CLUSTER:
```
3. Add an additional line at the bottom of the file:
```bash
# New line to add at the end of the file

#@ end
```  
## Enable the SecretGen Controller (Disabled on widows clusters)
1. Edit the file ~/.config/tanzu/tkg/providers/ytt/02_addons/secretgen-controller/add_secretgen-controller.yaml
2. Replace the if statement to support our mixed cluster scenario
```bash
# LINE TO REPLACE

#@ if data.values.PROVIDER_TYPE != "tkg-service-vsphere" and data.values.SECRETGEN_CONTROLLER_ENABLE and not data.values.IS_WINDOWS_WORKLOAD_CLUSTER:

# REPLACE WITH

#@ if data.values.PROVIDER_TYPE != "tkg-service-vsphere" and data.values.SECRETGEN_CONTROLLER_ENABLE:
#@ if data.values.IS_WINDOWS_WORKLOAD_CLUSTER and data.values.IS_MIXED_CLUSTER or not data.values.IS_WINDOWS_WORKLOAD_CLUSTER:
```  
3. Add an additional line at the bottom of the file:
```bash
# New line to add at the end of the file

#@ end
```  
## Scope windows update prevention to windows MD
1. Edit the file ~/.config/tanzu/tkg/providers/ytt/03_customizations/03_windows/prevent_windows_updates.yaml
2. Replace the overlay statement to support our mixed cluster scenario
```bash
# LINE TO REPLACE

#@overlay/match by=overlay.subset({"kind":"KubeadmConfigTemplate"}), expects="1+"

# REPLACE WITH

#@overlay/match by=overlay.subset({"kind":"KubeadmConfigTemplate", "metadata":{"name": data.values.CLUSTER_NAME + "-md-0-windows-containerd"}})

```  
## Scope Antrea Cleanup script to windows MD
1. Edit the file ~/.config/tanzu/tkg/providers/ytt/03_customizations/03_windows/register_antrea_cleanup.yaml
2. Replace the overlay statement to support our mixed cluster scenario
```bash
# LINE TO REPLACE

#@overlay/match by=overlay.subset({"kind":"KubeadmConfigTemplate"}), expects="1+"

# REPLACE WITH

#@overlay/match by=overlay.subset({"kind":"KubeadmConfigTemplate", "metadata":{"name": data.values.CLUSTER_NAME + "-md-0-windows-containerd"}})
```  
# File Additions
As we saw above i have introduced a new Variable "IS_MIXED_CLUSTER" which we need to declare in order for YTT to evaluate the template correctly
We also need to add an additional set of files to support multi Machine Deployment clusters at deployment time.
## Add Default Values files for this use case
1. Create a new file for our additional values and populate it with the needed values
```bash
cat << EOF > ~/.config/tanzu/tkg/providers/infrastructure-vsphere/ytt/mixed-cluster-default-values.yaml
#@data/values
#@overlay/match-child-defaults missing_ok=True
---
IS_MIXED_CLUSTER: false
VSPHERE_WORKER_NUM_CPUS_1:
VSPHERE_WORKER_DISK_GIB_1:
VSPHERE_WORKER_MEM_MIB_1:
WORKER_MACHINE_COUNT_1:
AUTOSCALER_MIN_SIZE_1:
AUTOSCALER_MAX_SIZE_1:
VSPHERE_DATASTORE_1:
VSPHERE_NETWORK_1:
EOF
```  
2. Add An overlay file to add the additional Machine Deployment
```bash
cat << EOF > ~/.config/tanzu/tkg/providers/infrastructure-vsphere/ytt/mixed-cluster-overlay.yaml
#@ load("@ytt:overlay", "overlay")
#@ load("@ytt:data", "data")
#@ if data.values.IS_MIXED_CLUSTER:
---
apiVersion: cluster.x-k8s.io/v1beta1
kind: MachineDeployment
metadata:
  labels:
    cluster.x-k8s.io/cluster-name: #@ data.values.CLUSTER_NAME
  #@ if data.values.ENABLE_AUTOSCALER:
  #@overlay/match missing_ok=True
  annotations:
    cluster.k8s.io/cluster-api-autoscaler-node-group-min-size: #@ data.values.AUTOSCALER_MIN_SIZE_1 or data.values.WORKER_MACHINE_COUNT_1 or data.values.WORKER_MACHINE_COUNT
    cluster.k8s.io/cluster-api-autoscaler-node-group-max-size: #@ data.values.AUTOSCALER_MAX_SIZE_1 or data.values.WORKER_MACHINE_COUNT_1 or data.values.WORKER_MACHINE_COUNT
  #@ end
  name: #@ "{}-md-linux".format(data.values.CLUSTER_NAME)
  namespace: #@ data.values.NAMESPACE
spec:
  clusterName: #@ data.values.CLUSTER_NAME
  replicas: #@ data.values.WORKER_MACHINE_COUNT_1 or data.values.WORKER_MACHINE_COUNT
  selector:
    matchLabels:
      cluster.x-k8s.io/cluster-name: #@ data.values.CLUSTER_NAME
  template:
    metadata:
      labels:
        cluster.x-k8s.io/cluster-name: #@ data.values.CLUSTER_NAME
        node-pool: #@ "{}-worker-pool".format(data.values.CLUSTER_NAME)
    spec:
      bootstrap:
        configRef:
          apiVersion: bootstrap.cluster.x-k8s.io/v1beta1
          kind: KubeadmConfigTemplate
          name: #@ "{}-md-linux".format(data.values.CLUSTER_NAME)
      clusterName: #@ data.values.CLUSTER_NAME
      infrastructureRef:
        apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
        kind: VSphereMachineTemplate
        name: #@ "{}-md-linux".format(data.values.CLUSTER_NAME)
      version: #@ data.values.KUBERNETES_VERSION
---
apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
kind: VSphereMachineTemplate
metadata:
  name: #@ "{}-md-linux".format(data.values.CLUSTER_NAME)
  namespace: #@ data.values.NAMESPACE
spec:
  template:
    spec:
      cloneMode: #@ data.values.VSPHERE_CLONE_MODE
      datacenter: #@ data.values.VSPHERE_DATACENTER
      datastore: #@ data.values.VSPHERE_DATASTORE_1 or data.values.VSPHERE_DATASTORE
      diskGiB: #@ data.values.VSPHERE_WORKER_DISK_GIB_1 or data.values.VSPHERE_WORKER_DISK_GIB
      folder: #@ data.values.VSPHERE_FOLDER
      memoryMiB: #@ data.values.VSPHERE_WORKER_MEM_MIB_1 or data.values.VSPHERE_WORKER_MEM_MIB
      network:
        devices:
        - dhcp4: true
          networkName: #@ data.values.VSPHERE_NETWORK_1 or data.values.VSPHERE_NETWORK
      numCPUs: #@ data.values.VSPHERE_WORKER_NUM_CPUS_1 or data.values.VSPHERE_WORKER_NUM_CPUS
      resourcePool: #@ data.values.VSPHERE_RESOURCE_POOL
      server: #@ data.values.VSPHERE_SERVER
      template: #@ data.values.VSPHERE_TEMPLATE
---
apiVersion: bootstrap.cluster.x-k8s.io/v1beta1
kind: KubeadmConfigTemplate
metadata:
  name:  #@ "{}-md-linux".format(data.values.CLUSTER_NAME)
  namespace: #@ data.values.NAMESPACE
spec:
  template:
    spec:
      useExperimentalRetryJoin: true
      joinConfiguration:
        nodeRegistration:
          criSocket: /var/run/containerd/containerd.sock
          kubeletExtraArgs:
            cloud-provider: external
            tls-cipher-suites: TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
          name: '{{ ds.meta_data.hostname }}'
      preKubeadmCommands:
      - hostname "{{ ds.meta_data.hostname }}"
      - echo "::1         ipv6-localhost ipv6-loopback" >/etc/hosts
      - echo "127.0.0.1   localhost" >>/etc/hosts
      - echo "127.0.0.1   {{ ds.meta_data.hostname }}" >>/etc/hosts
      - echo "{{ ds.meta_data.hostname }}" >/etc/hostname
      files: []
      users:
      - name: capv
        sshAuthorizedKeys:
        - #@ data.values.VSPHERE_SSH_AUTHORIZED_KEY
        sudo: ALL=(ALL) NOPASSWD:ALL
#@ end
EOF
```  
# Creating a mixed cluster
In the cluster config file make sure to add the following to what you would usually define:
```bash
#! Mandatory Fields
IS_WINDOWS_WORKLOAD_CLUSTER: true
IS_MIXED_CLUSTER: true

#! Optional Fields that will effect the linux Machine Deployment
VSPHERE_WORKER_NUM_CPUS_1:
VSPHERE_WORKER_DISK_GIB_1:
VSPHERE_WORKER_MEM_MIB_1:
WORKER_MACHINE_COUNT_1:
AUTOSCALER_MIN_SIZE_1:
AUTOSCALER_MAX_SIZE_1:
VSPHERE_DATASTORE_1:
VSPHERE_NETWORK_1:
```
