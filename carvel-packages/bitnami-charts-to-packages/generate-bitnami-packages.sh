declare -A arguments=();
declare -A variables=();
declare -i index=1;
variables["--temp-dir"]="temp_dir";
variables["--output-dir"]="output_dir";
variables["--generate-package-repository-manifest"]="generate_package_repository_manifest";
variables["--push-bundle-to-registry"]="push_bundle_to_registry";
variables["--registry-verify-certs"]="registry_verify_certs";
variables["--registry-username"]="registry_username";
variables["--registry-password"]="registry_password";
variables["--bundle-repository"]="bundle_repository";
variables["--number-of-chart-versions"]="number_of_chart_versions";
variables["--registry-ca-cert-path"]="registry_ca_cert_path";
variables["--registry-insecure"]="registry_insecure";
variables["--repo-sync-period"]="repo_sync_period";
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
Usage: generate-bitname-packages.sh [OPTIONS]

Options:

[General Flags]
  --help : show this help menu
  --generate-package-repository-manifest : (default: false)
  --push-bundle-to-registry : (default: false)
  --number-of-chart-versions : (default: 1)
  --output-dir : (default: /tmp/carvel-bitnami-packages)
  --temp-dir : (default: /tmp/helm-to-pkg)
  --repo-sync-period : (default: 6h)

[Registry Settings]
  --registry-password : (default: null)
  --registry-username : (default: null)
  --registry-verify-certs : (default: true)
  --registry-ca-cert-path : (default: null)
  --registry-insecure : (default: false)
  --bundle-repository : (default: null)

Example Usage:

[With Pushing a bundle to a self signed cert registry with authentication and the latest 5 chart versions]
generate-bitnami-packages.sh \\
  --push-bundle-to-registry true \\
  --number-of-chart-versions 5 \\
  --bundle-repository harbor.example.com/packages/bitnami-charts \\
  --registry-ca-cert-path /tmp/registry-ca-cert.crt \\
  --registry-username admin \\
  --registry-password VMware1!

[With generating a pkgr manifest and setting a custom sync interval for the repo of 12 hours]
generate-bitnami-packages.sh \\
  --push-bundle-to-registry true \\
  --bundle-repository harbor.example.com/packages/bitnami-charts \\
  --repo-sync-period 12h

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

if [[ $temp_dir ]]; then
  mkdir -p $temp_dir/bitnami
else
  mkdir -p /tmp/helm-to-pkg/bitnami
  temp_dir="/tmp/helm-to-pkg/bitnami"
fi

if [[ $output_dir ]]; then
  mkdir -p $output_dir/packages
else
  mkdir -p /tmp/carvel-bitnami-packages/packages
  output_dir="/tmp/carvel-bitnami-packages"
fi

if [[ $push_bundle ]]; then
  mkdir -p $output_dir/.imgpkg
fi

cd $temp_dir
helm search repo bitnami | awk '{print $1}' | tail -n +2 - > base-list.txt
while read line; do
  echo "Getting last $number_of_chart_versions versions of $line"
  mkdir -p $line
  helm search repo $line --versions -o json | jq -r .[0:$number_of_chart_versions] - | jq -r .[].version - | xargs -I % helm pull --untar $line --version % --untardir $line/%
done < base-list.txt
cd bitnami
for appFolder in *; do
    # this is needed as these charts fail to have their values schema outputted by readme-generator
    if [[ "$appFolder" != @("tensorflow-inception"|"bitnami-common"|"grafana-operator"|"mariadb-cluster"|"mean"|"mongodb"|"prometheus-operator"|"sugarcrm") ]]; then
      if [ -d "$appFolder" ]; then
        mkdir -p $output_dir/packages/$appFolder.bitnami.charts
	echo $appFolder
	temp_version=`helm search repo bitnami/$appFolder | awk '{print $2}' | tail -n +2`
	echo $temp_version
        yq .keywords[] $temp_dir/$appFolder/$temp_version/$appFolder/Chart.yaml -r | sed 's|^|  - |g' - > $appFolder-chart-categories.txt
        cat <<EOF > $output_dir/packages/$appFolder.bitnami.charts/metadata.yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  name: ${appFolder}.bitnami.charts
spec:
  displayName: "${appFolder}"
  longDescription: "Bitnami ${appFolder} Helm Chart"
  shortDescription: "${appFolder} Helm Chart"
  categories:
  - bitnami
  - helm
`cat $appFolder-chart-categories.txt`
EOF
        cd $temp_dir/$appFolder
        for versionFolder in *; do
          cd $temp_dir/$appFolder/$versionFolder
          APP_VERSION=`yq .appVersion $appFolder/Chart.yaml -r`
          CHART_VERSION=`yq .version $appFolder/Chart.yaml -r`
          CHART_DESCRIPTION=`yq .description $appFolder/Chart.yaml -r`
          echo $appFolder/$versionFolder
          readme-generator -v $appFolder/values.yaml --metadata values-schema.json
          if [ -f values-schema.json ]; then
            json2yml values-schema.json  > temp.yaml
            sed -i 's|^  |      |g' temp.yaml
            tail -n +2 temp.yaml > values-schema.yaml
            rm -f temp.yaml
            if [ -s values-schema.yaml ]; then
	      echo "Generating Package Manifest for $appFolder Chart version $versionFolder"
            else
	      echo "Skipping Generation of Package Manifest for $appFolder Chart version $versionFolder due to issue generating schema automatically"
              continue
            fi
          else
            echo "Skipping Generation of Package Manifest for $appFolder Chart version $versionFolder due to issue generating schema automatically"
            continue
          fi
          mkdir -p $output_dir/packages/$appFolder.bitnami.charts/$versionFolder
          cat <<EOF > $output_dir/packages/$appFolder.bitnami.charts/$versionFolder/package.yaml
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: ${appFolder}.bitnami.charts.${CHART_VERSION}
spec:
  refName: ${appFolder}.bitnami.charts
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
          name: ${appFolder}
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
        done
        cd $temp_dir
      fi
    fi
done

if [[ $generate_package_repository_manifest ]]; then
  if [[ $repo_sync_period ]]; then
    echo "generating package repository manifest"
  else
    echo "generating package repository manifest"
    repo_sync_period="6h"
  fi
  cat <<EOF > $output_dir/package-repository-manifest.yaml
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  finalizers:
  - finalizers.packagerepository.packaging.carvel.dev/delete
  name: bitnami-charts
spec:
  fetch:
    imgpkgBundle:
      image: $bundle_repository
  syncPeriod: $repo_sync_period
EOF
fi

if [[ $push_bundle_to_registry ]]; then
  cd $output_dir
  kbld -f ./packages/ -o ./.imgpkg/images.yaml
  if [[ $registry_verify_certs ]]; then
    registry_verify_certs="false"
  else
    registry_verify_certs="true"
  fi  

  if [[ $registry_insecure ]]; then
    registry_insecure="true"
  else
    registry_insecure="false"
  fi

  if [[ $registry_ca_cert_path ]]; then
    registry_needs_ca_path="true"
    echo "using cert at path $registry_ca_cert_path to authenticate against the reigstry"
  else
    registry_needs_ca_path="false"
  fi

  if [[ $registry_password ]]; then
    registry_needs_auth="true"
  else
    registry_needs_auth="false"
  fi

  if [[ $registry_needs_auth == "true" ]]; then
    if [[ $registry_needs_ca_path == "true" ]]; then
      imgpkg push -b $bundle_repository -f $output_dir --regitry-username $registry_username --registry-password $registry_password --registry-ca-cert-path $registry_ca_cert_path
    elif [[ $registry_insecure == "true" ]]; then
      imgpkg push -b $bundle_repository -f $output_dir --regitry-username $registry_username --registry-password $registry_password --registry-insecure=true
    elif [[ $registry_verify_certs == "false" ]]; then
      imgpkg push -b $bundle_repository -f $output_dir --regitry-username $registry_username --registry-password $registry_password --registry-verify-certs=false
    else
      imgpkg push -b $bundle_repository -f $output_dir --regitry-username $registry_username --registry-password $registry_password
    fi
  else
    if [[ $registry_needs_ca_path == "true" ]]; then
      imgpkg push -b $bundle_repository -f $output_dir --registry-ca-cert-path $registry_ca_cert_path
    elif [[ $registry_insecure == "true" ]]; then
      imgpkg push -b $bundle_repository -f $output_dir --registry-insecure=true
    elif [[ $registry_verify_certs == "false" ]]; then
      imgpkg push -b $bundle_repository -f $output_dir --registry-verify-certs=false
    else
      imgpkg push -b $bundle_repository -f $output_dir
    fi
  fi
fi
