#!/bin/bash
clear
mkdir $1-nsx-cert
cd $1-nsx-cert
echo "Generating Cert with OpenSSL"
openssl genrsa -out $1-private.key 2048  2>/dev/null 1>/dev/null
openssl req -new -key $1-private.key -out $1.csr -subj "/C=US/ST=CA/L=Palo Alto/O=VMware/OU=Antrea Cluster/CN=$1" 2>/dev/null 1>/dev/null
openssl x509 -req -days 3650 -in $1.csr -signkey $1-private.key -out $1.crt 2>/dev/null 1>/dev/null
ESCAPED_CERT=$(sed -z 's/\n/\\n/g' $1.crt)
echo "Creating Principal Identity in NSX-T via REST API"
curl -k -X POST -u ''"$3"':'"$4"'' --header "Content-Type: application/json" --data-raw '{"name":"'"$1"'","node_id":"'"$1"'","certificate_pem":"'"$ESCAPED_CERT"'","role":"enterprise_admin"}' https://$2/api/v1/trust-management/principal-identities/with-certificate
CERT_B64=`cat $1.crt | base64 -w 0`
KEY_B64=`cat $1-private.key | base64 -w 0`
echo -n ""
cat << EOF


# Values to add to your cluster config file

NSX_MANAGERS: "REPLACE ME!!!!!!!"
CNI: none
INSTALL_ANTREA_130: true
INSTALL_INTERWORKING_CONTROLLER: true
NSX_PRINCIPAL_IDENTITY_CERT_B64: $CERT_B64
NSX_PRINCIPAL_IDENTITY_KEY_B64: $KEY_B64
EOF

