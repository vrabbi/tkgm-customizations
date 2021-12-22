# Integrating TKGm 1.4 with NSX-T 3.2

## Pre Reqs
1. You must have NSX-T 3.2 installed
2. Admin access to NSX
3. copy the 4 yaml files from this directory to the path:
```bash
~/.config/tanzu/tkg/providers/ytt/04_user_customizations/
```  

## Procedure
1. Generate the Principal identity and the needed cert for the cluster to authenticate against NSX
```bash
# If your password has special charcters put single quotes around it when passing to the script
./gen-cert.sh <CLUSTER NAME> <NSX-T FQDN or VIP> <NSX-T ADMIN USER NAME> <NSX-T ADMIN PASSWORD>
```  
2. Copy the outputed values for the cert and key and place them in your cluster config file along with other required values as shown bellow
```bash
INSTALL_INTERWORKING_CONTROLLER: true
NSX_PRINCIPAL_IDENTITY_CERT_B64: <AS PER THE SCRIPTS OUTPUT>
NSX_PRINCIPAL_IDENTITY_KEY_B64: <AS PER THE SCRIPTS OUTPUT>
NSX_MANAGERS: "" # Comma Seperated list of your NSX Manager IPs eg. "1.1.1.1,2.2.2.2,3.3.3.3"
INSTALL_ANTREA_130: true # Current version of antrea in TKG isnt supported for this integration so we will install the OSS version
CNI: none # As we are deploying a custom CNI we need to set this value to none
```  
3. Create the cluster and enjoy the new integration!!!
