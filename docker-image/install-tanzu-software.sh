declare -A arguments=();
declare -A variables=();
declare -i index=1;
variables["--in-cluster"]="in_cluster";
variables["--grafana-password"]="grafana_password";
variables["--grafana-fqdn"]="grafana_fqdn";
variables["--dns-server-fqdn"]="dns_server_fqdn";
variables["--dns-zone"]="dns_zone";
variables["--dns-record-owner"]="dns_record_owner";
variables["--cluster-name"]="cluster_name";
variables["--mgmt-cluster-name"]="mgmt_cluster_name";
variables["--syslog-server"]="syslog_server";
variables["--syslog-port"]="syslog_port";
variables["--syslog-protocol"]="syslog_protocol";
variables["--syslog-format"]="syslog_format";
variables["--install-cert-manager"]="install_cert_manager";
variables["--install-contour"]="install_contour";
variables["--install-external-dns"]="install_external_dns";
variables["--install-prometheus"]="install_prometheus";
variables["--install-grafana"]="install_grafana";
variables["--install-fluent-bit"]="install_fluent_bit";
variables["--install-tbs"]="install_tbs";
variables["--install-tanzu-postgres"]="install_tanzu_postgres";
variables["--install-tanzu-rabbitmq"]="install_tanzu_rabbitmq";
variables["--install-tanzu-mysql"]="install_tanzu_mysql";
variables["--install-velero"]="install_velero";
variables["--tanzu-net-user"]="tanzu_net_user";
variables["--tanzu-net-password"]="tanzu_net_password";
variables["--rabbitmq-bundle"]="rabbitmq_bundle";
variables["--postgres-operator-repo"]="postgres_operator_repo";
variables["--postgres-instance-repo"]="postgres_instance_repo";
variables["--postgres-registry-fqdn"]="postgres_registry_fqdn";
variables["--postgres-registry-user"]="postgres_registry_user";
variables["--postgres-reqistry-password"]="postgres_registry_password";
variables["--tbs-bundle"]="tbs_bundle";
variables["--tbs-registry-repo"]="tbs_registry_repo";
variables["--tbs-registry-user"]="tbs_registry_user";
variables["--tbs-registry-password"]="tbs_registry_password";
variables["--tbs-registry-ca-cert-content"]="tbs_registry_ca_cert_content";
variables["--velero-s3-access-key"]="velero_s3_access_key";
variables["--velero-s3-secret-key"]="velero_s3_secret_key";
variables["--velero-s3-bucket-name"]="velero_s3_bucket_name";
variables["--velero-s3-region"]="velero_s3_region";
variables["--velero-s3-url"]="velero_s3_url";
variables["--help"]="help";
for i in "$@"
do
  arguments[$index]=$i;
  prev_index="$(expr $index - 1)";
  if [[ $i == *"="* ]]
    then argument_label=${i%=*}
    else argument_label=${arguments[$prev_index]}
  fi
  if [[ $i == "--help" ]]; then
    cat << EOF
Usage: install-tanzu-software.sh [FLAGS]

Options:

[General Flags]
  --help : show this help menu
  --in-cluster : (default: false)
  --install-cert-manager : (default: false)
  --install-contour : (default: false) 
  --install-external-dns : (default: false)
  --install-prometheus : (default: false)
  --install-grafana : (default: false)
  --install-fluent-bit : (default: false)
[Grafana Flags]
  --grafana-password : Base64 encoded password for Grafana admin user
  --grafana-fqdn : the FQDN to assign to the HTTPProxy for grafana secure HTTPS access
[External DNS Flags]
  --dns-server-fqdn : the DNS server to be targeted for managing DNS records by external DNS
  --dns-zone : the zone in which external DNS is allowed to create and manage records
  --dns-record-owner : should be a unique value per cluster - typically should be the TKG Cluster Name
[Fluent Bit Flags]
  --cluster-name: TKG Cluster Name - used to enrich logs shipped by fluent-bit
  --mgmt-cluster-name : TKG Management Cluster Name - used to enrich logs shipped by fluent-bit
  --syslog-server : where to ship the logs to
  --syslog-port : typically 514
  --syslog-protocol : typically udp
  --syslog-format : typically rfc5424

Alpha Flags:
[General Flags]
  --install-tbs : (default: false)
  --install-tanzu-postgres : (default: false)
  --install-tanzu-rabbitmq : (default: false)
  --install-tanzu-mysql : (default: false)
  --install-velero : (default: false)
  --tanzu-net-user : tanzunet / pivnet username (usually your email) 
  --tanzu-net-password : tanzunet / pivnet password
[RabbitMQ Flags]
  --rabbitmq-bundle : the url to the rabbitmq imgpkg bundle you imported to your environment
[PostgreSQL Flags]
  --postgres-operator-repo : the url to the tanzu psql operator image repo in your local registry
  --postgres-instance-repo : the url to the tanzu psql instance image repo in your local registry
  --postgres-registry-fqdn : the url to your container registry to which you uploaded the psql images and will be pulling from
  --postgres-registry-user : the username to authenticate to the psql image registry
  --postgres-reqistry-password : the password to authenticate to the psql image registry
[Tanzu Build Service Flags]
  --tbs-bundle : the url to the tanzu build service imgpkg bundle in your local registry
  --tbs-registry-repo : the url to the repo where tbs images are located in your local registry
  --tbs-registry-user : the username to authenticate to the tbs registry
  --tbs-registry-password : the password to authenticate to the tbs registry
  --tbs-registry-ca-cert-content : base64 encoded CA certificate of the registry used for TBS so as to be able to work with self signed certs
[Velero Flags]
  --velero-s3-access-key
  --velero-s3-secret-key
  --velero-s3-bucket-name
  --velero-s3-region
  --velero-s3-url

Example Usage (install all extensions on a TKGm 1.4 workload cluster on vSphere):
export GRAFANA_PASSWORD=`echo "VMware1!" | base64`
export GRAFANA_FQDN="grafana.tkg.terasky.demo"
export DNS_SERVER="dns01.terasky.demo"
export DNS_ZONE="tkg.terasky.demo"
export CLUSTER_NAME="tkg-cls-01"
export MGMT_CLUSTER_NAME="tkg-mgmt-cls"
export SYSLOG_SERVER="vrli.tkg.terasky.demo"
export SYSLOG_PORT=514
export SYSLOG_PROTOCOL="udp"
export SYSLOG_FORMAT="rfc5424"
export TEMP_KUBE_CONTEXT="\$CLUSTER_NAME-admin@\$CLUSTER_NAME"
kubectl config use-context \$TEMP_KUBE_CONTEXT
install-tanzu-software.sh \\
  --in-cluster true \\
  --install-cert-manager true \\
  --install-contour true \\
  --install-external-dns true \\
  --install-prometheus true \\
  --install-grafana true \\
  --install-fluent-bit true \\
  --grafana-password \$GRAFANA_PASSWORD \\
  --grafana-fqdn \$GRAFANA_FQDN \\
  --dns-server-fqdn \$DNS_SERVER \\
  --dns-zone \$DNS_ZONE \\
  --dns-record-owner \$CLUSTER_NAME \\
  --cluster-name \$CLUSTER_NAME \\
  --mgmt-cluster-name \$MGMT_CLUSTER_NAME \\
  --syslog-server \$SYSLOG_SERVER \\
  --syslog-port \$SYSLOG_PORT \\
  --syslog-protocol \$SYSLOG_PROTOCOL \\
  --syslog-format \$SYSLOG_FORMAT
EOF
    exit 1
  else
    if [[ -n $argument_label ]] ; then
      if [[ -n ${variables[$argument_label]} ]]
        then
            if [[ $i == *"="* ]]
                then declare ${variables[$argument_label]}=${i#$argument_label=}
              else declare ${variables[$argument_label]}=${arguments[$index]}
            fi
      fi
    fi
  fi
  index=index+1;
done;
# Actual Script
if [[ $in_cluster == "true" ]]; then
  kubectl config set-cluster cls --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt --server=https://kubernetes.default.svc
  kubectl config set-context cls --cluster=cls --user=cls
  kubectl config set-credentials cls --token=`cat /var/run/secrets/kubernetes.io/serviceaccount/token`
fi
if [[ $install_cert_manager == "true" ]]; then
  tanzu package install cert-manager --package-name cert-manager.tanzu.vmware.com --namespace tkg-packages --version 1.1.0+vmware.1-tkg.2 --create-namespace --kubeconfig ~/.kube/config
fi
if [[ $install_contour == "true" ]]; then
  if ! [[ -n $install_cert_manager ]]; then
    exit "Cert Manager Package is required. pleae add --install-cert-manager to your command and try again"
  fi
  cat << EOF > contour-data-values.yaml
---
infrastructure_provider: vsphere
namespace: tanzu-system-ingress
contour:
 configFileContents: {}
 useProxyProtocol: false
 replicas: 2
 pspNames: "vmware-system-restricted"
 logLevel: info
envoy:
 service:
   type: LoadBalancer
   annotations: {}
   nodePorts:
     http: null
     https: null
   externalTrafficPolicy: Cluster
   disableWait: false
 hostPorts:
   enable: true
   http: 80
   https: 443
 hostNetwork: false
 terminationGracePeriodSeconds: 300
 logLevel: info
 pspNames: null
certificates:
 duration: 8760h
 renewBefore: 360h
EOF
  tanzu package install contour --package-name contour.tanzu.vmware.com --version 1.17.1+vmware.1-tkg.1 --values-file contour-data-values.yaml --namespace tkg-packages --create-namespace --kubeconfig ~/.kube/config
fi
if [[ $install_external_dns == "true" ]]; then
  if ! [[ -n $install_cert_manager ]]; then
    exit "Cert Manager Package is required. pleae add --install-cert-manager to your command and try again"
  fi
  cat << EOF > external-dns-data-values.yaml
---
namespace: tanzu-system-service-discovery
deployment:
 args:
   - --source=service
   - --source=ingress
   - --source=contour-httpproxy
   - --domain-filter=$dns_zone
   - --policy=upsert-only
   - --registry=txt
   - --txt-owner-id=$dns_record_owner
   - --txt-prefix=external-dns-
   - --provider=rfc2136
   - --rfc2136-host=$dns_server_fqdn
   - --rfc2136-port=53
   - --rfc2136-zone=$dns_zone
   - --rfc2136-tsig-axfr
   - --rfc2136-insecure
 env: []
 securityContext: {}
 volumeMounts: []
 volumes: []
EOF
  tanzu package install external-dns --package-name external-dns.tanzu.vmware.com --version 0.8.0+vmware.1-tkg.1 --values-file external-dns-data-values.yaml --namespace tkg-packages --create-namespace --kubeconfig ~/.kube/config
fi
if [[ $install_prometheus == "true" ]]; then
  if ! [[ -n $install_cert_manager ]]; then
    exit "Cert Manager Package is required. pleae add --install-cert-manager to your command and try again"
  fi
  tanzu package install prometheus --package-name prometheus.tanzu.vmware.com --namespace tkg-packages --version 2.27.0+vmware.1-tkg.1 --create-namespace --kubeconfig ~/.kube/config
fi
if [[ $install_grafana == "true" ]]; then
  if ! [[ -n $install_cert_manager ]]; then
    exit "Cert Manager Package is required. pleae add --install-cert-manager to your command and try again"
  fi
  cat << EOF > grafana-data-values.yaml
---
namespace: tanzu-system-dashboards
grafana:
  secret:
    admin_user: YWRtaW4K
    admin_password: $grafana_password
ingress:
  virtual_host_fqdn: $grafana_fqdn
EOF
  tanzu package install grafana --package-name grafana.tanzu.vmware.com --namespace tkg-packages --version 7.5.7+vmware.1-tkg.1 --create-namespace --values-file grafana-data-values.yaml --kubeconfig ~/.kube/config
fi
if [[ $install_fluent_bit == "true" ]]; then
  cat << EOF > fluent-bit-data-values.yaml
---
namespace: "tanzu-system-logging"
fluent_bit:
  config:
    service: |
      [Service]
        Flush         1
        Log_Level     info
        Daemon        off
        Parsers_File  parsers.conf
        HTTP_Server   On
        HTTP_Listen   0.0.0.0
        HTTP_Port     2020
    outputs: |
      [OUTPUT]
        Name              stdout
        Match             *
      [OUTPUT]
        Name   syslog
        Match  kube.*
        Host   $syslog_server
        Port   $syslog_port
        Mode   $syslog_protocol
        Syslog_Format        $syslog_format
        Syslog_Hostname_key  tkg_cluster
        Syslog_Appname_key   pod_name
        Syslog_Procid_key    container_name
        Syslog_Message_key   message
        Syslog_SD_key        k8s
        Syslog_SD_key        labels
        Syslog_SD_key        annotations
        Syslog_SD_key        tkg
      [OUTPUT]
        Name   syslog
        Match  kube_systemd.*
        Host   $syslog_server
        Port   $syslog_port
        Mode   $syslog_protocol
        Syslog_Format        $syslog_format
        Syslog_Hostname_key  tkg_cluster
        Syslog_Appname_key   tkg_instance
        Syslog_Message_key   MESSAGE
        Syslog_SD_key        systemd
    inputs: |
      [INPUT]
        Name tail
        Path /var/log/containers/*.log
        Parser docker
        Tag kube.*
        Mem_Buf_Limit 5MB
        Skip_Long_Lines On
      [INPUT]
        Name              tail
        Tag               audit.*
        Path              /var/log/audit/audit.log
        Parser            logfmt
        DB                /var/log/flb_system_audit.db
        Mem_Buf_Limit     50MB
        Refresh_Interval  10
        Skip_Long_Lines   On
      [INPUT]
        Name                systemd
        Tag                 kube_systemd.*
        Path                /var/log/journal
        DB                  /var/log/flb_kube_systemd.db
        Systemd_Filter      _SYSTEMD_UNIT=kubelet.service
        Systemd_Filter      _SYSTEMD_UNIT=containerd.service
        Read_From_Tail      On
        Strip_Underscores   On
      [INPUT]
        Name              tail
        Tag               apiserver_audit.*
        Path              /var/log/kubernetes/audit.log
        Parser            json
        DB                /var/log/flb_kube_audit.db
        Mem_Buf_Limit     50MB
        Refresh_Interval  10
        Skip_Long_Lines   On
    filters: |
      [FILTER]
        Name                kubernetes
        Match               kube.*
        Kube_URL            https://kubernetes.default.svc:443
        Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
        Kube_Tag_Prefix     kube.var.log.containers.
        Merge_Log           On
        Merge_Log_Key       log_processed
        K8S-Logging.Parser  On
        K8S-Logging.Exclude On
      [FILTER]
        Name                record_modifier
        Match               *
        Record tkg_cluster $cluster_name
        Record tkg_instance $mgmt_cluster_name
      [FILTER]
        Name                  nest
        Match                 kube.*
        Operation             nest
        Wildcard              tkg_instance*
        Nest_Under            tkg
      [FILTER]
        Name                  nest
        Match                 kube_systemd.*
        Operation             nest
        Wildcard              SYSTEMD*
        Nest_Under            systemd
      [FILTER]
        Name                  modify
        Match                 kube.*
        Copy                  kubernetes k8s
      [FILTER]
        Name                  nest
        Match                 kube.*
        Operation             lift
        Nested_Under          kubernetes
    parsers: ""
    streams: ""
    plugins: ""
  daemonset:
    resources: {}
    podAnnotations: {}
    podLabels: {}
EOF
  tanzu package install fluent-bit --package-name fluent-bit.tanzu.vmware.com --namespace tkg-packages --version 1.7.5+vmware.1-tkg.1 --create-namespace --values-file fluent-bit-data-values.yaml --kubeconfig ~/.kube/config
fi
if [[ $install_tanzu_mysql == "true" ]]; then
  if ! [[ -n $install_cert_manager ]]; then
    exit "Cert Manager Package is required. pleae add --install-cert-manager to your command and try again"
  fi
  export HELM_EXPERIMENTAL_OCI=1
  helm registry login registry.pivotal.io -u $tanzu_net_user -p $tanzu_net_password --insecure
  helm chart pull registry.pivotal.io/tanzu-mysql-for-kubernetes/tanzu-mysql-operator-chart:1.0.0
  kubectl create namespace tanzu-mysql-for-kubernetes-system
  kubectl create secret docker-registry tanzu-mysql-image-registry --docker-server=https://registry.pivotal.io/ --docker-username=$tanzu_net_user --docker-password=$tanzu_net_password -n tanzu-mysql-for-kubernetes-system
  helm chart export registry.pivotal.io/tanzu-mysql-for-kubernetes/tanzu-mysql-operator-chart:1.0.0
  helm upgrade --install tanzu-sql-with-mysql-operator ./tanzu-sql-with-mysql-operator/ -n tanzu-mysql-for-kubernetes-system
  kubectl wait --for=condition=Available deployment/tanzu-sql-with-mysql-operator --timeout=10m0s -n tanzu-mysql-for-kubernetes-system
fi
if [[ $install_tanzu_postgres == "true" ]]; then
  if ! [[ -n $install_cert_manager ]]; then
    exit "Cert Manager Package is required. pleae add --install-cert-manager to your command and try again"
  fi
  kubectl create ns tanzu-postgres-system
  export HELM_EXPERIMENTAL_OCI=1
  helm registry login registry.pivotal.io -u $tanzu_net_user -p $tanzu_net_password --insecure
  helm chart pull registry.pivotal.io/tanzu-sql-postgres/postgres-operator-chart:v1.2.0
  helm chart export registry.pivotal.io/tanzu-sql-postgres/postgres-operator-chart:v1.2.0  --destination=/tmp/
  kubectl create secret docker-registry regsecret --docker-server=https://registry.pivotal.io/ --docker-username=$tanzu_net_user --docker-password=$tanzu_net_password --namespace tanzu-postgres-system
  helm upgrade --install --wait postgres-operator /tmp/postgres-operator/ -n tanzu-postgres-system
  kubectl wait --for=condition=Available deployment/postgres-operator --timeout=10m0s --namespace tanzu-postgres-system
fi
if [[ $install_tanzu_rabbitmq == "true" ]]; then
  if ! [[ -n $install_cert_manager ]]; then
    exit "Cert Manager Package is required. pleae add --install-cert-manager to your command and try again"
  fi
  imgpkg pull -b $rabbitmq_bundle --registry-verify-certs=false -o ./bundle
  cd bundle/
  kubectl create namespace rabbitmq-system
  ytt -f manifests/cluster-operator.yml -f manifests/messaging-topology-operator-with-certmanager.yaml | kbld -f .imgpkg/images.yml -f config/ -f- | kapp -y deploy -a rabbitmq-operator -f -
fi
if [[ $install_tbs == "true" ]]; then
  if ! [[ -n $install_cert_manager ]]; then
    exit "Cert Manager Package is required. pleae add --install-cert-manager to your command and try again"
  fi
  echo $tbs_registry_ca_cert_content | base64 -d > ./ca.crt
  imgpkg pull -b $tbs_bundle -o /tmp/bundle --registry-ca-cert-path ./ca.crt
  ytt -f /tmp/bundle/values.yaml \
      -f /tmp/bundle/config/ \
      -f ./ca.crt \
      -v docker_repository="$tbs_registry_repo" \
      -v docker_username="$tbs_registry_user" \
      -v docker_password="$tbs_registry_password" \
      -v tanzunet_username="$tanzu_net_user" \
      -v tanzunet_password="$tanzu_net_password" \
      | kbld -f /tmp/bundle/.imgpkg/images.yml -f- \
      | kapp deploy -a tanzu-build-service -f- -y
fi


#############################
if [[ $install_velero == "true" ]]; then
  cat << EOF > velero-creds.toml
[default]
aws_access_key_id=$velero_s3_access_key
aws_secret_access_key=$velero_s3_secret_key
EOF
  velero install --provider aws --plugins "velero/velero-plugin-for-aws:v1.1.0" --bucket $velero_s3_bucket_name --secret-file ./velero-creds.toml --backup-location-config "region=$velero_s3_region,s3ForcePathStyle=true,s3Url=$velero_s3_url" --snapshot-location-config region="default"
  velero plugin add vsphereveleroplugin/velero-plugin-for-vsphere:1.1.0
  velero snapshot-location create vsl-vsphere --provider velero.io/vsphere
fi

