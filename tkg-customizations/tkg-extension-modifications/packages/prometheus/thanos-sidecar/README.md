# Adding Thanos Sidecar to Tanzu Prometheus Package 1.4

## Issue
The TKG Extension for Prometheus doesnt enclude Thanos which is needed at large scale and when we want to keep data for a long time. 

## Workaround
I have created the following files to streamline the process until VMware hopefully supports Thanos OOTB with the current prometheus or even better support the Prometheus Operator.

## Process
1. run install.sh like follows
```bash
 ./install.sh <CLUSTER NAME>
``` 
