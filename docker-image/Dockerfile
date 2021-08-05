FROM ubuntu:bionic
LABEL maintainer="Scott Rosenberg"
LABEL description="Container for installing TKG 1.3.1 Extensions and Tanzu Advanced Suite Products"
RUN apt-get update -y \
    && apt-get install -y gzip curl wget perl jq ca-certificates \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN wget -O- https://carvel.dev/install.sh | bash
RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
COPY tanzu-mysql-deployment-templates-1.0.0.tgz postgres-for-kubernetes-v1.1.0.tar.gz tkg-extensions-manifests-v1.3.1-vmware.1.tar.gz attach-to-vrops.sh kubectl-linux-v1.20.5-vmware.1.gz install-extensions.sh install-tanzu-mysql.sh install-tanzu-postgres.sh vrops-add-k8s-adapter-body.json velero-creds install-velero.sh velero-linux-v1.5.3_vmware.1.gz install-tanzu-rabbitmq.sh attach-to-tmc.sh tmc install-tanzu-build-service.sh ./
RUN gzip -d kubectl-linux-v1.20.5-vmware.1.gz \
    && chmod +x kubectl-linux-v1.20.5-vmware.1 \
    && mv kubectl-linux-v1.20.5-vmware.1 /usr/local/bin/kubectl \
    && tar -zxvf tkg-extensions-manifests-v1.3.1-vmware.1.tar.gz \
    && tar -zxvf postgres-for-kubernetes-v1.1.0.tar.gz \
    && tar -xvf tanzu-mysql-deployment-templates-1.0.0.tgz \
    && gzip -d velero-linux-v1.5.3_vmware.1.gz \
    && chmod +x velero-linux-v1.5.3_vmware.1 \
    && mv velero-linux-v1.5.3_vmware.1 /usr/local/bin/velero \
    && chmod +x install-extensions.sh \
    && chmod +x install-tanzu-mysql.sh \
    && chmod +x install-tanzu-postgres.sh \
    && chmod +x attach-to-vrops.sh \
    && chmod +x install-velero.sh \
    && chmod +x install-tanzu-rabbitmq.sh \
    && chmod +x attach-to-tmc.sh \
    && chmod +x tmc \
    && chmod +x install-tanzu-build-service.sh \
    && mv tmc /usr/local/bin/tmc \
    && rm -f tanzu-mysql-deployment-templates-1.0.0.tgz postgres-for-kubernetes-v1.1.0.tar.gz tkg-extensions-manifests-v1.3.1-vmware.1.tar.gz postgres-for-kubernetes-v1.1.0/images/postgres-operator postgres-for-kubernetes-v1.1.0/images/postgres-instance /usr/local/bin/kwt /tanzu-mysql-deployment-templates-1.0.0/open_source_license_VMware_Tanzu*
