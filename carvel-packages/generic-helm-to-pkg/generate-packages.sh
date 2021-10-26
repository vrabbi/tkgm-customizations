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
variables["--package-suffix"]="package_suffix";
variables["--helm-repository-name"]="helm_repository_name";
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
Usage: generate-helm-packages.sh [OPTIONS]

Options:

[General Flags]
  --help : show this help menu
  --generate-package-repository-manifest : (default: false)
  --push-bundle-to-registry : (default: false)
  --number-of-chart-versions : (default: 1)
  --output-dir : (default: /tmp/carvel-helm-packages)
  --temp-dir : (default: /tmp/helm-to-pkg)
  --repo-sync-period : (default: 6h)
  --package-suffix : (default: terasky.labs)
  --helm-repository-name : (default: null)

[Registry Settings]
  --registry-password : (default: null)
  --registry-username : (default: null)
  --registry-verify-certs : (default: true)
  --registry-ca-cert-path : (default: null)
  --registry-insecure : (default: false)
  --bundle-repository : (default: null)

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
if [[ $package_suffix ]]; then
  echo "Creating packages withe a custom suffix"
else
  package_suffix="terasky.labs"
fi
echo $helm_repository_name
helm search repo $helm_repository_name | awk '{print $1}' | tail -n +2 - > base-list.txt
sed -i 's|.*/||g' base-list.txt

repo=$helm_repository_name

chart_repo_url=`helm repo list -o json | jq -r --arg repo "$repo" ' .[] | select(.name==$repo) | .url '`
while read line; do
  chart_name=$line
  mkdir -p output/packages/$chart_name.$package_suffix

  cat <<EOF > output/packages/$chart_name.$package_suffix/metadata.yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  name: ${chart_name}.${package_suffix}
spec:
  displayName: "${chart_name}"
  longDescription: "${chart_name} Helm Chart"
  shortDescription: "${chart_name} Helm Chart"
  categories:
  - helm
EOF

  versions=`helm search repo $helm_repository_name/$chart_name --versions -o json | jq -r .[0:$number_of_chart_versions] - | jq -r .[].version -`
  for ver in $versions
  do
    cleanVer=`echo ${ver//v}`
    mkdir -p output/packages/$chart_name.$package_suffix/$cleanVer
    helm show values $helm_repository_name/$chart_name --version $ver > output/packages/$chart_name.$package_suffix/$cleanVer/original-values.yaml
    helm show chart $helm_repository_name/$chart_name --version $ver > output/packages/$chart_name.$package_suffix/$cleanVer/Chart.yaml
    sed '/#/d' output/packages/$chart_name.$package_suffix/$cleanVer/original-values.yaml | sed '/^\s*$/d' - > output/packages/$chart_name.$package_suffix/$cleanVer/cleaned-values.yaml
    echo "## @section parameters" > output/packages/$chart_name.$package_suffix/$cleanVer/final-values.yaml
    /snap/bin/yq r output/packages/$chart_name.$package_suffix/$cleanVer/cleaned-values.yaml --printMode p "**" | sed 's|^|## @param |g' - | sed 's|\.\[|\[|g' - | sed 's/\[[0-9]\]$//g' - >> output/packages/$chart_name.$package_suffix/$cleanVer/final-values.yaml
    cat output/packages/$chart_name.$package_suffix/$cleanVer/cleaned-values.yaml >> output/packages/$chart_name.$package_suffix/$cleanVer/final-values.yaml
    sed -i 's|: null|: ""|g' output/packages/$chart_name.$package_suffix/$cleanVer/final-values.yaml
    readme-generator -v output/packages/$chart_name.$package_suffix/$cleanVer/final-values.yaml -m output/packages/$chart_name.$package_suffix/$cleanVer/values-schema.json
    json2yml output/packages/$chart_name.$package_suffix/$cleanVer/values-schema.json | sed 's|^  |      |g' - | tail -n +2 - > output/packages/$chart_name.$package_suffix/$cleanVer/values-schema.yaml
    cat <<EOF > output/packages/$chart_name.$package_suffix/$cleanVer/package.yaml
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: ${chart_name}.${package_suffix}.${cleanVer}
spec:
  refName: ${chart_name}.${package_suffix}
  version: ${cleanVer}
  releaseNotes: |
        Auto Generated Package for the ${helm_repository_name} - ${chart_name} Helm Chart
  valuesSchema:
    openAPIv3:
`cat output/packages/$chart_name.$package_suffix/$cleanVer/values-schema.yaml`
  template:
    spec:
      fetch:
      - helmChart:
          name: ${chart_name}
          version: "${ver}"
          repository:
            url: "${chart_repo_url}"
      template:
      - helmTemplate: {}
      deploy:
      - kapp:
          delete:
            rawOptions: ["--apply-ignored=true"]
EOF
    rm -f output/packages/$chart_name.$package_suffix/$cleanVer/Chart.yaml          
    rm -f output/packages/$chart_name.$package_suffix/$cleanVer/cleaned-values.yaml 
    rm -f output/packages/$chart_name.$package_suffix/$cleanVer/final-values.yaml   
    rm -f output/packages/$chart_name.$package_suffix/$cleanVer/original-values.yaml
    rm -f output/packages/$chart_name.$package_suffix/$cleanVer/values-schema.json  
    rm -f output/packages/$chart_name.$package_suffix/$cleanVer/values-schema.yaml  
  done
done < base-list.txt

if [[ $push_bundle_to_registry ]]; then
  mkdir -p output/.imgpkg
fi

if [[ $generate_package_repository_manifest ]]; then
  if [[ $repo_sync_period ]]; then
    echo "generating package repository manifest"
  else
    echo "generating package repository manifest"
    repo_sync_period="6h"
  fi
  cat <<EOF > output/package-repository-manifest.yaml
---
apiVersion: packaging.carvel.dev/v1alpha1
kind: PackageRepository
metadata:
  finalizers:
  - finalizers.packagerepository.packaging.carvel.dev/delete
  name: $helm_repository_name-charts
spec:
  fetch:
    imgpkgBundle:
      image: $bundle_repository
  syncPeriod: $repo_sync_period
EOF
fi

if [[ $push_bundle_to_registry ]]; then
  kbld -f output/packages/ --imgpkg-lock-output output/.imgpkg/images.yml
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
      imgpkg push -b $bundle_repository -f output --registry-username $registry_username --registry-password $registry_password --registry-ca-cert-path $registry_ca_cert_path
    elif [[ $registry_insecure == "true" ]]; then
      imgpkg push -b $bundle_repository -f output --registry-username $registry_username --registry-password $registry_password --registry-insecure=true
    elif [[ $registry_verify_certs == "false" ]]; then
      imgpkg push -b $bundle_repository -f output --registry-username $registry_username --registry-password $registry_password --registry-verify-certs=false
    else
      imgpkg push -b $bundle_repository -f output --registry-username $registry_username --registry-password $registry_password
    fi
  else
    if [[ $registry_needs_ca_path == "true" ]]; then
      imgpkg push -b $bundle_repository -f output --registry-ca-cert-path $registry_ca_cert_path
    elif [[ $registry_insecure == "true" ]]; then
      imgpkg push -b $bundle_repository -f output --registry-insecure=true
    elif [[ $registry_verify_certs == "false" ]]; then
      imgpkg push -b $bundle_repository -f output --registry-verify-certs=false
    else
      imgpkg push -b $bundle_repository -f output
    fi
  fi
fi
rm -f base-list.txt
