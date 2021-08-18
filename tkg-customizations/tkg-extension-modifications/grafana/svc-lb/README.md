# Changing the Service Type for the Grafana instances deployed with TKG 1.3.1 extensions.

## Issue
The TKG Extension for Grafana says it supports Service Type LoadBalancer and NodePort and that actually they are the defaults but it does not! 
The value that should be used based on the docs: monitoring.grafana.service.type does absolutely nothing!!!!! 

## Findings
After debugging why it wasnt working the following was found: 
1. the defaults are purely false and it is always ClusterIP
2. No YTT overlay was created to change the Service Type

## Workaround
I have created the following files to streamline the process until VMware either unclaim support for something which is not possible with thier manifests or fix the manifests.

## Process
1. Define the service type as per the documentation in your data values file (an example is in this repo)
2. Make any additional changes to the data values file as you usually would (ingress fqdn, PV size, Storage class etc.)
3. create a secret with our overlay file (grafana-service-overlay.yaml):
```bash
kubectl create secret generic grafana-service-overlay -n tanzu-system-monitoring --from-file=service-overlay.yaml=grafana-service-overlay.yaml
``` 
4. Create a secret for the data values file content:
```bash
kubectl -n tanzu-system-monitoring create secret generic grafana-data-values --from-file=values.yaml=grafana-data-values.yaml
``` 
5. Deploy the Grafana Extension with the grafana-extensions.yaml file from this repo:
```bash
kubectl apply -f grafana-extension.yaml 
```
