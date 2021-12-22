# Adding LDAP Authentication to the Grafana instances deployed with TKG 1.3.1 extensions.

## Issue
The TKG Extension for Grafana says it supports LDAP auth but it does not! 
The value that should be used based on the docs: monitoring.grafana.secret.ldap_toml does absolutely nothing!!!!! 

## Findings
After debugging why it wasnt working the following was found: 
1. The ldap_toml value is placed as a value in the secret named grafana in the tanzu-system-monitoring namespace
2. the ldap_toml value is not mounted to the grafana pod
3. No YTT overlay exists in the TKG extensions bundle to make the needed updates to the deployment
4. this also requires changing the grafana.ini file to enable ldap

## Workaround
I have created the following files to streamline the process until VMware either unclaim support for something which is not possible with thier manifests or fix the manifests.

## Process
1. Edit the ldap.toml file with your AD settings
2. base64 encode the content of that file. for example on linux you can run:
```bash
cat ldap.toml | base64 -w 0
``` 
3. Edit the grafana-data-values.yaml file from this repo and add your base64 encoded content of ldap.toml in the relvant field (monitoring.grafana.secret.ldap_toml)
4. If you want to change anything in the grafana.ini file you can make the changes to the grafana_ini fields value i have added in the grafana-data-values.yaml file
5. Make any additional changes to the data values file as you usually would (ingress fqdn, PV size, Storage class etc.)
6. create a secret with our overlay file (grafana-ldap-overlay.yaml):
```bash
kubectl create secret generic grafana-ldap-overlay -n tanzu-system-monitoring --from-file=ldap-overlay.yaml=grafana-ldap-overlay.yaml
``` 
7. Create a secret for the data values file content:
```bash
kubectl -n tanzu-system-monitoring create secret generic grafana-data-values --from-file=values.yaml=grafana-data-values.yaml
``` 
8. Deploy the Grafana Extension with the grafana-extensions.yaml file from this repo:
```bash
kubectl apply -f grafana-extension.yaml 
```
