# Deploying TKG with Calico Operator using Typha and Route Reflectors as the CNI

## Background

The Calico implementation which is provided OOTB with TKG does not have support for routable pods and also does not have Typha in its datapath.

The issue with Calico with KDD (and not ETCD) in terms of scale is because every calico-node pod creates watches against the API server which at scales above around 50 worker nodes can cause throttling of the API server as per the tigera documentation.

Typha is a sort of middleware which sits between the calico-node pods and the API server.

The Typha daemon sits between the datastore (such as the Kubernetes API server) and many instances of Felix. Typha&#39;s main purpose is to increase scale by reducing each node&#39;s impact on the datastore. Services such as Felix and confd connect to Typha instead of connecting directly to the datastore as Typha maintains a single datastore connection on behalf of all its clients. It caches the datastore state and deduplicates events so that they can be fanned out to many listeners.

Typha is deployed as a Deployment and can be scaled anywhere between 1-20 instances.

Each Typha pod can handle hundreds of Calico Nodes making it a very scalable solution.

Tigera have updated us that Typha has been validated at larger scales currently then the ETCDv3 datastore and is the correct path to go down.

## Calico Installation type

There are many ways to install and configure Calico. This can be done using a helm chart, using the raw yaml files provided by Tigera or can be done using the new Calico Operator.

As the operator is the new and suggested model of deploying Calico due to its added value of easing upgrades and making management overall much smoother this is the path we have decided makes the most sense.

## Calicoctl

Currently in order to configure calico settings around BGP this must be done using the dedicated CLI tool &quot;calicoctl&quot; which must be installed on the nodes of the cluster.

As calicoctl is not installed by default in TKG nodes we have added the functionality via the preKubeadmCommands section of the KubeadmConfigTemplate and the KubeadmControlPlane CRs to download the binary from the calico github repo and make it executable.

By doing it this way we ensure that CalicoCTL is installed on all kubernetes nodes deployed via TKG which makes work much easier.

## Typha design

The Calico operator has typha enabled by default. The operator also has the internal logic around scaling Typha according to there best practices which makes its configuration transparent to the end user

## Future Improvements

Currently in Tech Preview, there is a new functionality which allows setting all configurations which currently must be done via calicoctl by creating CRs directly against the K8s API.

While I have tested this and it works as expected, because this is only in tech preview we believe this should be only done in a future release when this new functionality has been battle tested and is officially GAed by Tigera.

This functionality will greatly simplify the process but currently is not something we recommend.

## Using a custom CNI in TKG

TKG comes with 2 options for manged CNI implementations:

1. Antrea
2. Calico

As we want to use Calico but the Calico implementation is not suitable for all needs we will use the 3rd option provided by VMware.

This option is what is called "Bring Your Own CNI".

In this approach you set the CNI value in the cluster configuration to "none".

By doing this TKG does not install a CNI and it is up to the user to install and manage the CNI implementation in there clusters.

While the documentation explains how to do this, the method which is documented requires manual installation of the CNI.

We have built the functionality using the options available to us in ClusterAPI the backing technology of TKG to automatically install and configure Calico.

The technology stack we use in order to achieve this is a mixture of three different components:

1. YTT – this is the templating mechanism used in TKG for templating out and rendering the final cluster YAML definitions within the tanzu CLI.
2. ClusterResourceSet (CRS) – this is a core clusterAPI CRD which enables saving YAML files in either secrets or configmaps and then referencing them in this CR. This CR has a section called clusterSelector which is a basic label selector for Cluster CRs. When a cluster with the matching labels is found the ClusterAPI controller applys the YAML files which are present in the referenced ConfigMaps and Secrets into the Cluster. This is a mechanism which allows us to automate the installation of any Kubernetes YAMLs at cluster creation time.
3. preKubeadmCommand / postKubeadmCommands – these fields in the kubeadmControlPlane and KubeadmConfigTemplate CRs enables us to run commands on all nodes in a cluster automatically at the time of provisioning by utilizing the runcmd option of Cloud-init which is the mechanism used to bootstrap the nodes in TKG.

In order to streamline the process as much as possible we have made it so that every configuration value needed in the implementation of this custom CNI architecture can be declared in the TKG Cluster config file.

## New Variables we have added for this mechanism

1. CUSTOM\_CALICO\_DEPLOYMENT
2. CALICO\_BGP\_OPTION – Enabled or Disabled (default Disabled)
3. CALICO\_BLOCK\_SIZE – default is 28
4. CALICO\_POD\_CIDR – the POD CIDR to be configured in the Calico IPAM for PODs
5. CALICO\_ENCAPSULATION – the default value is VXLANCrossSubnet
6. CALICO\_NAT\_OUTGOING – Disabled or Enabled (Default Enabled)
7. INSTALL\_CALICOCTL – true or false (default false)
8. CALICO\_ROUTE\_REFLECTORS – base64 encoded string containing the YAML documents for the BGPPeer CRs referencing the Route Reflectors (described in the next section)
9. CALICO\_BGP\_AS\_NUMBER – the AS number for Calico BGP configuration
10. CONFIGURE\_CALICO\_BGP\_SETTINGS – true or false (default false)

## BGP configuration

As calicoctl must be used in order to configure BGP routing in calico, we install the CLI as described above on all nodes.

We also must configure 2 types of custom resources:

1. BGPConfiguration
2. BGPPeers

### BGPConfiguration Resource

This resource is where we need to configure if node to node mesh should be enabled or not and is also where we configure the AS number for this calico deployment.

We need to disable the node to node mesh in the desired configuration and we need to set the AS number based on the input variable CALICO\_BGP\_AS\_NUMBER which we have added as mentioned above.

The YAML stanza of such a resource looks like the following
```bash
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  nodeToNodeMeshEnabled: false
  asNumber: #@ data.values.CALICO\_BGP\_AS\_NUMBER
```  
As can be seen we have hardcoded all values except the asNumber field which is parameterized to use the YTT templating mechanism and overlay the user provided value at runtime.

### BGPPeer Resource

The BGP Peer resource is a resource which is more complex to deal with. While the BGPConfiguration is a 1 to 1 relation in our case with a cluster, the BGPPeer resource is not such. There will be multiple BGPPeers per cluster.

Another difference is that there are multiple different values which need to be provided to each of the BGPPeer resources (name,IP,AS Number etc.)

Currently the TKG cluster configuration file does not allow for complex inputs (in our case it would need to be an array of maps) which would be needed in order to templatize this resource.

Because of this we have gone down a different path which is currently the easiest option which we can hopefully improve in the future.

The mechanism we have configured is that the user will supply a base64 encoded string of the YAML Manifests for BGPPeers and we will instantiate that in the cluster by decoding it and applying it using calicoctl.

#### Example file of BGPPeers
```bash
apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: test1
spec:
  peerIP: 1.1.1.1
  asNumber: 0
---
apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: test2
spec:
  peerIP: 2.2.2.2
  asNumber: 1
```  
#### base64 encoding the file

if the file is for example saved in the /tmp folder and has the name bgppeers.yaml:
```bash
cat /tmp/bgppeers.yaml | base64 -w 0
```  
This command will output the value we will then put in the cluster configuration file in order to instantiate the BGPPeers.

the output of the above example YAML and this command would be for example:
``` bash
YXBpVmVyc2lvbjogcHJvamVjdGNhbGljby5vcmcvdjMKa2luZDogQkdQUGVlcgptZXRhZGF0YToKICBuYW1lOiB0ZXN0MQpzcGVjOgogIHBlZXJJUDogMS4xLjEuMQogIGFzTnVtYmVyOiAwCi0tLQphcGlWZXJzaW9uOiBwcm9qZWN0Y2FsaWNvLm9yZy92MwpraW5kOiBCR1BQZWVyCm1ldGFkYXRhOgogIG5hbWU6IHRlc3QyCnNwZWM6CiAgcGVlcklQOiAyLjIuMi4yCiAgYXNOdW1iZXI6IDEK
```  
