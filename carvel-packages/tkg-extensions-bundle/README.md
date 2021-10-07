# Easy install of TKG Extensions
This is an example of how to install TKG extensions in an opinionated but easy way on TKG 1.4 on vSphere

## Steps
1. Deploy a worklaod cluster
2. retrieve the admin kubeconfig for the cluster
``` bash
tanzu cluster kubeconfig get --admin <CLUSTER_NAME>
```  
3. change to the context of the cluster
``` bash
kubectl config use-context <WORKLOAD CLUSTER CONTEXT NAME>
```  
4. Add the package to the cluster
``` bash
kubectl apply -f metadata.yaml
kubectl apply -f package.yaml
```  
5. Create a values.yaml file
``` bash
cat << EOF > values.yaml
domain: 
cluster_name: 
mgmt_cluster_name: 
dns_server: 
syslog_server: 
grafana_admin_password: 
grafana_fqdn:
grafana_enable_ldap: false
ldap_host:
ldap_port: 636
ldap_use_ssl: true
ldap_start_tls: false
ldap_skip_ssl_verify: true
ldap_bind_dn:
ldap_bind_password:
user_search_base_dn:
group_search_base_dn:
EOF
```  
6. update the values file with your relevant inputs
7. install the package
``` bash
tanzu package install tkg-extensions --package-name tkg-extensions.terasky.com --version 1.4.0 --values-file values.yaml
```  
8. wait a few minutes and all extensions should be ready to go. you can follow the status with the command:
``` bash
kubectl get pkgi
```  
Note: it is expected for some package along the way to be in a reconcile failed status. this is fixed automatically as dependant components are reconciled.
