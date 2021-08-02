sed -i "s|<TKG_CLUSTER_NAME>|$1|g" vrops-add-k8s-adapter-body.json
sed -i "s|<API_SERVER_URL>|$2|g" vrops-add-k8s-adapter-body.json
BEARER_TOKEN=`cat /var/run/secrets/kubernetes.io/serviceaccount/token`
sed -i "s|<BEARER_TOKEN>|$BEARER_TOKEN|g" vrops-add-k8s-adapter-body.json
curl -k https://$3/suite-api/api/adapters -H "Accept: application/json" -H "Content-Type: application/json" -u $4:$5 -d "@vrops-add-k8s-adapter-body.json" -X POST > response.json
curl -k https://$3/suite-api/api/adapters -H "Accept: application/json" -H "Content-Type: application/json" -u $4:$5 -d "@response.json" -X PATCH
adapterID=$(cat response.json | jq .id)
adapterID=$(echo $adapterID | sed -e 's/^"//' -e 's/"$//')
curl -k https://$3/suite-api/api/adapters/$adapterID/monitoringstate/start -H "Accept: application/json" -H "Content-Type: application/json" -u $4:$5 -X PUT
