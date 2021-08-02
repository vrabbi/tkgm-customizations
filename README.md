# TKGm Customization Repo
This repository containes experimental examples for how to customize TKGm to provision clusters with additional capabilities beyond the standard offering of TKGm.
The repository is not well documented currently and does not follow in all cases best practices and should be used as a starting point / point of reference and not considered by any means as production ready at this point. 
There are 2 main folders in the Repo:
1. docker-image - containes scripts and a Dockerfile to build a docker image needed for running many of the custom installations
2. tkg-customizations - YAML / YTT templates for customizing TKGm

## Key Functionality included in this repo
### 1. Create Clusters with Multiple Machine Deployments
By default TKGm only creates a single Machine Deployment (MD-0) 
there are many use cases where a homogeneous cluster is not optimal and we need to go down a hetrogeneous cluster approach. 
Examples: 
1. Nodes of different sizes
2. Nodes with Different OSes
3. Nodes with GPUs and nodes without GPUs
4. Nodes on different underlying networks

### 2. Install TKG Extensions Automatically
TKGm comes with optional extensions that you can install which will provide additional capabilities to your cluster.
The TKGm Extensions currently are:
1. Monitoring - Prometheus + Grafana
2. Ingress (Layer 7 Load Balancing) - Contour
3. DNS Management for services and ingress resources - External DNS
4. Log Aggregation - FluentBit
5. Container Registry - Harbor
6. Backup and Restore - Velero

While these extensions are available and supported, there is no OOTB way to install them automatically on every new cluster. this repo contains A way to do this

### 3. Automated installation of Tanzu Advanced Products
TKGm comes at all levels of licensing of the Tanzu suite. when we purchase it as part of the Tanzu Advanced suite or purchase for example the Tanzu Data Services package on its own, we may want to automate the deployment of the different operators provided automatically on all of are clusters.
Examples:
1. Auto install the Tanzu RabbitMQ Operators
2. Auto install the Tanzu MySQL Operator
3. Auto install the Tanzu Postgres Operator

### 4. Attach clusters to external systems
Kubernetes clusters many times need to be attached to external systems. these could be Tanzu SaaS offerings or different solutions.
Examples:
1. Add cluster as a K8s endpoint in VROPS for monitroing
2. Attach cluster to Tanzu Mission Control (TMC)
3. Attach cluster to Tanzu Observability (Wavefront)

### 5. Trusting an internal CA Certificate
Many times we need our clusters to trust an organizations internal CA. in order to do this we must add custom YTT templates and the CA PEM file in order for it to be trusted automatically by all nodes

