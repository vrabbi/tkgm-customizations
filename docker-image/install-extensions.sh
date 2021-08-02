kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager  --version v1.0.2 --set installCRDs=true --wait --timeout=10m0s
cd tkg-extensions-v1.3.1+vmware.1/extensions
kubectl apply -f service-discovery/external-dns/namespace-role.yaml
cp service-discovery/external-dns/external-dns-data-values-rfc2136-with-contour.yaml.example service-discovery/external-dns/external-dns-data-values-rfc2136-with-contour.yaml
sed -i "s/k8s/$3/g" service-discovery/external-dns/external-dns-data-values-rfc2136-with-contour.yaml
sed -i "s/192.168.0.1/$9/g" service-discovery/external-dns/external-dns-data-values-rfc2136-with-contour.yaml
sed -i "s/--rfc2136-tsig-keyname=externaldns-key/--rfc2136-insecure/g" service-discovery/external-dns/external-dns-data-values-rfc2136-with-contour.yaml
sed -i "/--rfc2136-tsig-secret/d" service-discovery/external-dns/external-dns-data-values-rfc2136-with-contour.yaml
sed -i "s/=my-zone.example.org/=$10/g" service-discovery/external-dns/external-dns-data-values-rfc2136-with-contour.yaml
sed -i "/^    - --source=service/a '    - --source=ingress'" service-discovery/external-dns/external-dns-data-values-rfc2136-with-contour.yaml
sed -i "s/'//g" service-discovery/external-dns/external-dns-data-values-rfc2136-with-contour.yaml
kubectl create secret generic external-dns-data-values --from-file=values.yaml=service-discovery/external-dns/external-dns-data-values-rfc2136-with-contour.yaml -n tanzu-system-service-discovery
kubectl apply -f service-discovery/external-dns/external-dns-extension.yaml
kubectl wait --for=condition=ReconcileSucceeded -n tanzu-system-service-discovery apps.kappctrl.k14s.io/external-dns --timeout=10m0s
kubectl apply -f ingress/contour/namespace-role.yaml
cp ingress/contour/vsphere/contour-data-values-lb.yaml.example ingress/contour/vsphere/contour-data-values.yaml
kubectl create secret generic contour-data-values --from-file=values.yaml=ingress/contour/vsphere/contour-data-values.yaml -n tanzu-system-ingress
kubectl apply -f ingress/contour/contour-extension.yaml
kubectl wait --for=condition=ReconcileSucceeded -n tanzu-system-ingress apps.kappctrl.k14s.io/contour --timeout=10m0s
kubectl apply -f monitoring/prometheus/namespace-role.yaml
cp monitoring/prometheus/prometheus-data-values.yaml.example monitoring/prometheus/prometheus-data-values.yaml
kubectl create secret generic prometheus-data-values --from-file=values.yaml=monitoring/prometheus/prometheus-data-values.yaml -n tanzu-system-monitoring
kubectl apply -f monitoring/prometheus/prometheus-extension.yaml
kubectl wait --for=condition=ReconcileSucceeded -n tanzu-system-monitoring apps.kappctrl.k14s.io/prometheus --timeout=10m0s
cp monitoring/grafana/grafana-data-values.yaml.example monitoring/grafana/grafana-data-values.yaml
sed -i "s/<ADMIN_PASSWORD>/$1\n    ingress:\n      virtual_host_fqdn: $2/g" monitoring/grafana/grafana-data-values.yaml
kubectl apply -f monitoring/grafana/namespace-role.yaml
kubectl -n tanzu-system-monitoring create secret generic grafana-data-values --from-file=values.yaml=monitoring/grafana/grafana-data-values.yaml
kubectl apply -f monitoring/grafana/grafana-extension.yaml
kubectl wait --for=condition=ReconcileSucceeded -n tanzu-system-monitoring apps.kappctrl.k14s.io/grafana --timeout=10m0s
GRAFANA_POD=`kubectl get po -n tanzu-system-monitoring -l "app.kubernetes.io/name=grafana" -o jsonpath="{.items[0].metadata.name}"`
B64D_PWD=`echo $1 | base64 -d`
kubectl exec -it -n tanzu-system-monitoring $GRAFANA_POD --container grafana -- /usr/share/grafana/bin/grafana-cli admin reset-admin-password $B64D_PWD
kubectl apply -f logging/fluent-bit/namespace-role.yaml
cp logging/fluent-bit/syslog/fluent-bit-data-values.yaml.example logging/fluent-bit/syslog/fluent-bit-data-values.yaml
sed -i "s/<TKG_INSTANCE_NAME>/$3/g" logging/fluent-bit/syslog/fluent-bit-data-values.yaml
sed -i "s/<CLUSTER_NAME>/$4/g" logging/fluent-bit/syslog/fluent-bit-data-values.yaml
sed -i "s/<SYSLOG_HOST>/$5/g" logging/fluent-bit/syslog/fluent-bit-data-values.yaml
sed -i "s/<SYSLOG_PORT>/$6/g" logging/fluent-bit/syslog/fluent-bit-data-values.yaml
sed -i "s/<SYSLOG_MODE>/$7/g" logging/fluent-bit/syslog/fluent-bit-data-values.yaml
sed -i "s/<SYSLOG_FORMAT>/$8/g" logging/fluent-bit/syslog/fluent-bit-data-values.yaml
kubectl create secret generic fluent-bit-data-values --from-file=values.yaml=logging/fluent-bit/syslog/fluent-bit-data-values.yaml -n tanzu-system-logging
kubectl apply -f logging/fluent-bit/fluent-bit-extension.yaml
kubectl wait --for=condition=ReconcileSucceeded -n tanzu-system-logging apps.kappctrl.k14s.io/fluent-bit --timeout=10m0s
