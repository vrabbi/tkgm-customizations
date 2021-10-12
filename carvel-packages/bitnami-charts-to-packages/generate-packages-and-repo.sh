#!/bin/bash

mkdir -p /tmp/helm-to-pkg
cd /tmp/helm-to-pkg
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo bitnami | awk '{print $1}' > list-of-charts.txt
tail -n +2 list-of-charts.txt | xargs helm pull --untar
for f in *; do
    # this is needed as these charts fail to have their values schema outputted by readme-generator
    if [[ "$f" != @("tensorflow-inception"|"bitnami-common"|"grafana-operator"|"mariadb-cluster"|"mean"|"mongodb"|"prometheus-operator"|"sugarcrm") ]]; then
      if [ -d "$f" ]; then
          cd $f
          APP_VERSION=`yq .appVersion Chart.yaml -r`
          CHART_VERSION=`yq .version Chart.yaml -r`
          CHART_DESCRIPTION=`yq .description Chart.yaml -r`
          echo $f
          readme-generator -v values.yaml --metadata values-schema.json
          if [ -f values-schema.json ]; then
            json2yml values-schema.json  > temp.yaml
            sed -i 's|^  |      |g' temp.yaml
            tail -n +2 temp.yaml > values-schema.yaml
            rm -f temp.yaml
            if [ -s values-schema.yaml ]; then
              echo "Continuing"
            else
              continue
            fi
          else
            continue
          fi
          mkdir -p /tmp/carvel-bitnami-packages/packages/$f.bitnami.charts
          cat <<EOF > /tmp/carvel-bitnami-packages/packages/$f.bitnami.charts/metadata.yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  name: ${f}.bitnami.charts
spec:
  displayName: "${f}"
  longDescription: "Bitnami ${f} ${APP_VERSION} - Helm Chart version ${CHART_VERSION}"
  shortDescription: "${f} Version ${APP_VERSION}"
  categories:
  - bitnami
  - helm
EOF
          cat <<EOF > /tmp/carvel-bitnami-packages/packages/$f.bitnami.charts/${CHART_VERSION}.yaml
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: ${f}.bitnami.charts.${CHART_VERSION}
spec:
  refName: ${f}.bitnami.charts
  version: ${CHART_VERSION}
  releaseNotes: |
        ${CHART_DESCRIPTION}
  valuesSchema:
    openAPIv3:
`cat values-schema.yaml`
  template:
    spec:
      fetch:
      - helmChart:
          name: ${f}
          version: "${CHART_VERSION}"
          repository:
            url: https://charts.bitnami.com/bitnami
      template:
      - helmTemplate: {}
      deploy:
      - kapp:
          delete:
            rawOptions: ["--apply-ignored=true"]
EOF
        cd ..
      fi
    fi
done
