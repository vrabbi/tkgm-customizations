declare -A arguments=();
declare -A variables=();
declare -i index=1;
variables["--temp-dir"]="temp_dir";
variables["--output-dir"]="output_dir";
variables["--generate-package-repository-manifest"]="generate_package_repository_manifest";
variables["--number-of-chart-versions"]="number_of_chart_versions";
variables["--repo-sync-period"]="repo_sync_period";
variables["--oci-registry-fqdn"]="oci_registry_fqdn";
variables["--oci-image-repository"]="oci_image_repository";
variables["--package-repository-name"]="package_repository_name";
variables["--help"]="help";
variables["--chart-list-file-path"]="chart_list_file_path";
variables["--package-repository-tag"]="package_repository_tag";
variables["--helm-repo-url"]="helm_repo_url";
variables["--helm-repo-name"]="helm_repo_name";
variables["--add-helm-repo"]="add_helm_repo";
variables["--package-domain-suffix"]="package_domain_suffix";
variables["--running-in-container"]="running_in_container";
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
Usage: generate-bitnami-packages.sh [OPTIONS]

Options:

[Mandatory Flags]
  --oci-registry-fqdn : The OCI registry FQDN to push bundles to - (default: null)
  --oci-image-repository : The OCI Registry Project / Repo / Sub Path to place all bundles in - (default: null)
  --package-repository-name : The Name of the package repository bundle - (default: null)
  --package-repository-tag : The Tag for the generated package repository - (default: null)
  --number-of-chart-versions : The latest X number of chart versions to generate packages for (default: null)

[Optional Flags]
  --help : show this help menu
  --output-dir : (default: /tmp/carvel-bitnami-packages) - DONT SET WHEN RUNNING IN CONTAINER
  --temp-dir : (default: /tmp/helm-to-pkg) - DONT SET WHEN RUNNING IN CONTAINER
  --repo-sync-period : The sync period on the package repository yaml - (default: 6h)
  --chart-list-file-path : An optional file with the charts to convert to packages in the format <HELM REPO NAME>/<CHART NAME> . When not supplied entire bitnami repo will be converted - (default: null)
  --helm-repo-url : The Helm Repo URL for the bitnami or TAC helm repo. - (default: https://charts.bitnami.com/bitnami)
  --helm-repo-name : The Helm Repo name for the bitnami or TAC helm repo locally. - (default: bitnami)
  --add-helm-repo : A boolean flag to enable adding a non existent helm repo. (default: false)
  --package-domain-suffix : Package names require a naming convention of <APP NAME>.x.y . This parameter allows configuring the x.y suffix. - (default: bitnami.charts)

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

# Validate that flags were passed to the invocation
if [[ ${#arguments[@]} -eq 1 ]]; then
  if [[ $1 == "--running-in-container" ]]; then
    echo "No Flags were passed. Run with --help flag to get usage information"
  fi
fi
if [[ ${#arguments[@]} -eq 0 ]]; then
  echo "No Flags were passed. Run with --help flag to get usage information"
fi

# Validate Mandatory Flags were supplied
if ! [[ $oci_registry_fqdn || $oci_image_repository || $package_repository_name || $number_of_chart_versions ]]; then
  echo "Mandatory flags were not passed. use --help for usage information"
  exit 1
fi

echo "Starting Script"

# set start time variable for printing time at end of script
start=`date +%s`

if [[ $temp_dir ]]; then
  mkdir -p $temp_dir/bitnami
  mkdir -p $temp_dir/lock-files
else
  mkdir -p /tmp/helm-to-pkg/bitnami
  mkdir -p /tmp/helm-to-pkg/bitnami/lock-files
  temp_dir="/tmp/helm-to-pkg/bitnami"
fi

if [[ $output_dir ]]; then
  mkdir -p $output_dir/packages
else
  mkdir -p /tmp/carvel-bitnami-packages/packages
  output_dir="/tmp/carvel-bitnami-packages"
fi

if [[ $helm_repo_url ]]; then
  echo "We will utilize the helm repository at the following URL: $helm_repo_url"
else
  helm_repo_url="https://charts.bitnami.com/bitnami"
  echo "We will utilize the helm repository at the following URL: $helm_repo_url"
fi

if [[ $helm_repo_name ]]; then
  echo "We will utilize the helm repository with the name: $helm_repo_name"
else
  helm_repo_name="bitnami"
  echo "We will utilize the helm repository with the name: $helm_repo_name"
fi

if [[ $add_helm_repo == "true" ]]; then
  echo "Adding the helm repository $helm_repo_name found at $helm_repo_url"
  helm repo add $helm_repo_name $helm_repo_url --force-update
  helm repo update
else
  echo "Updating the cache for the helm repository $helm_repo_name"
  helm repo update
  repolist=`helm repo list -o json`
  if [[ $repolist == "[]" ]]; then
    echo "No Helm Repo Exists. Adding the repo $helm_repo_name found at $helm_repo_url"
    helm repo add $helm_repo_name $helm_repo_url --force-update
    helm repo update
  fi
fi

if [[ $package_domain_suffix ]]; then
  echo "Using a custom domain suffix"
  echo "Packages will be generated with the naming convention <CHART NAME>.$package_domain_suffix"
else
  package_domain_suffix="bitnami.charts"
  echo "Packages will be generated with the naming convention <CHART NAME>.$package_domain_suffix"
fi

mkdir -p $output_dir/.imgpkg
cd $temp_dir

if [[ $chart_list_file_path ]]; then
  echo "Using the Supplied chart list"
  cp $chart_list_file_path base-list.txt
else
  echo "Finding all maintained charts in the $helm_repo_name Repo"
  helm search repo $helm_repo_name | sed '/DEPRECATED/d' - | awk '{print $1}' | tail -n +2 - > base-list.txt
fi

while read line; do
  echo "Getting last $number_of_chart_versions versions of $line"
  mkdir -p $line
  helm search repo $line --versions -o json | jq -r .[0:$number_of_chart_versions] - | jq -r .[].version - | xargs -I % helm pull --untar $line --version % --untardir $line/%
done < base-list.txt
cd $helm_repo_name
for appFolder in *; do
    # this is needed as these charts fail to have their values schema outputted by readme-generator
    if [[ "$appFolder" != @("bitnami-common") ]]; then
      if [ -d "$appFolder" ]; then
        mkdir -p $output_dir/packages/$appFolder.$package_domain_suffix
	temp_version=`ls $temp_dir/$helm_repo_name/$appFolder | shuf -n 1`
        yq .keywords[] $temp_dir/$helm_repo_name/$appFolder/$temp_version/$appFolder/Chart.yaml -r | sed 's|^|  - |g' - > $appFolder-chart-categories.txt
        cat <<EOF > $output_dir/packages/$appFolder.$package_domain_suffix/metadata.yaml
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: PackageMetadata
metadata:
  name: ${appFolder}.${package_domain_suffix}
spec:
  displayName: "${appFolder}"
  longDescription: "Bitnami ${appFolder} Helm Chart"
  shortDescription: "${appFolder} Helm Chart"
  categories:
  - bitnami
  - helm
`cat $appFolder-chart-categories.txt`
EOF
        cd $temp_dir/$helm_repo_name/$appFolder
        for versionFolder in *; do
          cat $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$appFolder/values.yaml | yq . | jq '. as $input | . | paths | select(.[-1] | tostring | test("^(repository|tag)$"; "ix")) | . as $path | ( $input | getpath($path) ) as $members | { "key": ( $path | join(".") ), "value": $members } ' 2> /dev/null | jq -s 'from_entries' | sed 's/://g' - | xargs -I % echo % > $temp_dir/$helm_repo_name/$appFolder/$versionFolder/images.tmp
          tail -n +2 $temp_dir/$helm_repo_name/$appFolder/$versionFolder/images.tmp | sed '$ d' - > $temp_dir/$helm_repo_name/$appFolder/$versionFolder/images.txt
          sed 's/ .*//' $temp_dir/$helm_repo_name/$appFolder/$versionFolder/images.txt | xargs -I % echo "%" | awk 'BEGIN{FS=OFS="."}NF--' | sort -u > $temp_dir/$helm_repo_name/$appFolder/$versionFolder/paths.txt
          cat << EOF > $temp_dir/$helm_repo_name/$appFolder/$versionFolder/kbld-config.yaml
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
minimumRequiredVersion: 0.29.0
searchRules:
- keyMatcher:
    path: [images, {allIndexes: true}]
EOF
          cat $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$appFolder/values.yaml | yq . > $temp_dir/$helm_repo_name/$appFolder/$versionFolder/values.json
          cat $temp_dir/$helm_repo_name/$appFolder/$versionFolder/paths.txt | xargs -I % jq -c '.%.registry + "/" + .%.repository + ":" + .%.tag' $temp_dir/$helm_repo_name/$appFolder/$versionFolder/values.json > $temp_dir/$helm_repo_name/$appFolder/$versionFolder/images.list.tmp
	  grep -E '[a-zA-Z0-9\._-]+\/+[a-zA-Z0-9\._-]+:[a-zA-Z0-9]+.*' $temp_dir/$helm_repo_name/$appFolder/$versionFolder/images.list.tmp > $temp_dir/$helm_repo_name/$appFolder/$versionFolder/images.list
          sed -i 's/^/  - /g' $temp_dir/$helm_repo_name/$appFolder/$versionFolder/images.list
	  sed -i '/  - "\/:"/d' $temp_dir/$helm_repo_name/$appFolder/$versionFolder/images.list
          # Handle Sub Charts
	  echo "Checking path $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$appFolder/charts/"
	  if [[ -d "${temp_dir}/${helm_repo_name}/${appFolder}/${versionFolder}/${appFolder}/charts" ]]; then
	    cd $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$appFolder/charts
            ls -d * | while read d
            do
	      mkdir -p $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d
	      cat $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$appFolder/charts/$d/values.yaml | yq . > $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d/values.json
              cat $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$appFolder/charts/$d/values.yaml | yq . | jq '. as $input | . | paths | select(.[-1] | tostring | test("^(registry|repository|tag)$"; "ix")) | . as $path | ( $input | getpath($path) ) as $members | { "key": ( $path | join(".") ), "value": $members } ' |     jq -s 'from_entries' | sed 's/://g' - | xargs -I % echo % > $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d/images.tmp
              tail -n +2 $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d/images.tmp | sed '$ d' - > $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d/images.txt
              sed 's/ .*//' $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d/images.txt | xargs -I % echo "%" | awk 'BEGIN{FS=OFS="."}NF--' | sort -u > $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d/paths.txt
              cat $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d/paths.txt | xargs -I % jq -c '.%.registry + "/" + .%.repository + ":" + .%.tag' $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d/values.json > $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d/images.list.tmp
              grep -E '[a-zA-Z0-9\._-]+\/+[a-zA-Z0-9\._-]+:[a-zA-Z0-9]+.*' $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d/images.list.tmp > $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d/images.list
              sed -i 's/^/  - /g' $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d/images.list
              sed -i '/  - "\/:"/d' $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d/images.list
	      cat $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$d/images.list >> $temp_dir/$helm_repo_name/$appFolder/$versionFolder/images.list
            done
          fi
	  cd $temp_dir/$helm_repo_name/$appFolder/$versionFolder
	  sed -i '1s/^/images:\n/' $temp_dir/$helm_repo_name/$appFolder/$versionFolder/images.list
	  mkdir -p $output_dir/packages/$appFolder.$package_domain_suffix/$versionFolder/.imgpkg
	  mkdir -p $output_dir/packages/$appFolder.$package_domain_suffix/$versionFolder/config
	  kbld -f $temp_dir/$helm_repo_name/$appFolder/$versionFolder/images.list -f $temp_dir/$helm_repo_name/$appFolder/$versionFolder/kbld-config.yaml --imgpkg-lock-output $output_dir/packages/$appFolder.$package_domain_suffix/$versionFolder/.imgpkg/images.yml --registry-verify-certs=false 1> /dev/null
	  cp -r $temp_dir/$helm_repo_name/$appFolder/$versionFolder/$appFolder/* $output_dir/packages/$appFolder.$package_domain_suffix/$versionFolder/config/
          cd $temp_dir/$helm_repo_name/$appFolder/$versionFolder
          APP_VERSION=`yq .appVersion $appFolder/Chart.yaml -r`
          CHART_VERSION=`yq .version $appFolder/Chart.yaml -r`
          CHART_DESCRIPTION=`yq .description $appFolder/Chart.yaml -r`
          
          readme-generator -v $appFolder/values.yaml --metadata values-schema.json 1> /dev/null
          if [ -f values-schema.json ]; then
            json2yaml values-schema.json  > temp.yaml
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
	  imgpkg push -b ${oci_registry_fqdn}/${oci_image_repository}/${appFolder}.${package_domain_suffix}:${CHART_VERSION} -f $output_dir/packages/$appFolder.${package_domain_suffix}/$versionFolder/ --registry-verify-certs=false --lock-output $temp_dir/lock-files/$appFolder-lock-file.yaml 1> /dev/null
          cat <<EOF > $output_dir/packages/$appFolder.${package_domain_suffix}/$versionFolder/package.yaml
---
apiVersion: data.packaging.carvel.dev/v1alpha1
kind: Package
metadata:
  name: ${appFolder}.${package_domain_suffix}.${CHART_VERSION}
spec:
  refName: ${appFolder}.${package_domain_suffix}
  version: ${CHART_VERSION}
  releaseNotes: |
        ${CHART_DESCRIPTION}
  valuesSchema:
    openAPIv3:
`cat values-schema.yaml`
  template:
    spec:
      fetch:
      - imgpkgBundle:
          image: ${oci_registry_fqdn}/${oci_image_repository}/${appFolder}.${package_domain_suffix}:${CHART_VERSION}
      template:
      - helmTemplate:
          path: "config/"
      - kbld:
          paths:
          - "-"
          - ".imgpkg/images.yml"
      deploy:
      - kapp:
          delete:
            rawOptions: ["--apply-ignored=true"]
EOF
          cd $temp_dir/$helm_repo_name/$appFolder
        done
        cd $temp_dir/$helm_repo_name
      fi
    fi
done

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
  name: $package_repository_name
spec:
  fetch:
    imgpkgBundle:
      image: ${oci_registry_fqdn}/${oci_image_repository}/$package_repository_name:$package_repository_tag
  syncPeriod: $repo_sync_period
EOF

cd $output_dir
find . -type d -name config -exec rm -rf {} \; 1>/dev/null 2>/dev/null
find packages/ -type d -name .imgpkg -exec rm -rf {} \; 1>/dev/null 2>/dev/null
kbld -f ./packages/ --imgpkg-lock-output ./.imgpkg/images.yml --registry-verify-certs=false 1> /dev/null
imgpkg push -b ${oci_registry_fqdn}/${oci_image_repository}/${package_repository_name} -f $output_dir --registry-verify-certs=false --lock-output $temp_dir/lock-files/repository-lock-file.yaml 1> /dev/null
cp -r $temp_dir/lock-files $output_dir/
package_repo_url=`cat $output_dir/lock-files/repository-lock-file.yaml | yq .bundle.image -j`
package_repo_sha=${package_repo_url#*@}

if [[ $running_in_container ]]; then
  mkdir -p /output/lock-files
  mkdir -p /output/package-repo-files
  cp -r $temp_dir/lock-files/* /output/lock-files/
  cp -r $output_dir/packages /output/package-repo-files/
  cp -r $output_dir/.imgpkg /output/package-repo-files/
  cp $output_dir/package-repository-manifest.yaml /output/
fi
echo "Done Generating the bundles!"
end=`date +%s`
runtime=$((end-start))
hours=$((runtime / 3600))
minutes=$(( (runtime % 3600) / 60 ))
seconds=$(( (runtime % 3600) % 60 ))
echo ""
echo "Script Runtime: $hours:$minutes:$seconds (hh:mm:ss)"
echo ""
echo ""
echo "#############################################################################################################"
echo "### To use this package repo in a non air gapped environment you can choose any of the following options: ###"
echo "#############################################################################################################"
echo ""
echo "1. Add as a global package to your tanzu cluster with default settings:"
echo "    tanzu package repository add $package_repository_name --url $package_repo_url --namespace tanzu-package-repo-global"
echo "2. Add as a global package to your tanzu cluster with custom sync interval:"
echo "    kubectl apply -n tanzu-package-repo-global -f $output_dir/package-repository-manifest.yaml"
echo ""
echo ""
echo "###############################"
echo "### Air Gapped Instructions ###"
echo "###############################"
echo ""
echo "1. Run the following command to copy all packages and images into a tar ball on your machine:"
echo "    imgpkg copy -b $package_repo_url --to-tar /tmp/my-repo.tar --registry-verify-certs=false"
echo "2. Import the Tar file to the airgapped environment"
echo "3. Run the following to import the artifacts to an OCI registry in your air gapped environment:"
echo "    imgpkg copy --tar /tmp/my-repo.tar --to-repo <AIR GAPPED REGISTRY>/<AIR GAPPED REPO NAME>@$package_repo_sha --registry-verify-certs=false"
echo "4. Add the repo to your cluster as per the instructions above while taking care to replace the URL with the new location"
echo ""
echo ""
echo "Enjoy!!!"
