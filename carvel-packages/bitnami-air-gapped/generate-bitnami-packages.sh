declare -A arguments=();
declare -A variables=();
declare -i index=1;
variables["--temp-dir"]="temp_dir";
variables["--output-dir"]="output_dir";
variables["--generate-package-repository-manifest"]="generate_package_repository_manifest";
variables["--number-of-chart-versions"]="number_of_chart_versions";
variables["--repo-sync-period"]="repo_sync_period";
variables["--registry"]="registry";
variables["--repository"]="repository";
variables["--package-repository-name"]="package_repository_name";
variables["--help"]="help";
variables["--chart-list-file-path"]="chart_list_file_path"
variables["--package-repository-tag"]="package_repository_tag"
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

[Mandatory Flags]
  --registry : The OCI registry FQDN to push bundles to - (default: null)
  --repository : The OCI Registry Project / Repo / Sub Path to place all bundles in - (default: null)
  --package-repository-name : The Name of the package repository bundle - (default: null)
  --package-repository-tag : The Tag for the generated package repository - (default: null)
  --number-of-chart-versions : The latest X number of chart versions to generate packages for (default: null)

[Optional Flags]
  --help : show this help menu
  --output-dir : (default: /tmp/carvel-bitnami-packages)
  --temp-dir : (default: /tmp/helm-to-pkg)
  --repo-sync-period : The sync period on the package repository yaml - (default: 6h)
  --chart-list-file-path : An optional file with the charts to convert to packages in the format bitnami/<CHART NAME> . When not supplied entire bitnami repo will be converted - (default: null)

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

mkdir -p $output_dir/.imgpkg

cd $temp_dir
if [[ $chart_list_file_path ]]; then
  echo "Using the Supplied chart list"
  cp $chart_list_file_path base-list.txt
else
  echo "Finding all maintained charts in the Bitnami Repo"
  helm search repo bitnami | sed '/DEPRECATED/d' - | awk '{print $1}' | tail -n +2 - > base-list.txt
fi
while read line; do
  echo "Getting last $number_of_chart_versions versions of $line"
  mkdir -p $line
  helm search repo $line --versions -o json | jq -r .[0:$number_of_chart_versions] - | jq -r .[].version - | xargs -I % helm pull --untar $line --version % --untardir $line/%
done < base-list.txt
cd bitnami
for appFolder in *; do
    # this is needed as these charts fail to have their values schema outputted by readme-generator
    if [[ "$appFolder" != @("bitnami-common") ]]; then
      if [ -d "$appFolder" ]; then
        mkdir -p $output_dir/packages/$appFolder.bitnami.charts
	temp_version=`helm search repo bitnami/$appFolder | awk '{print $2}' | tail -n +2`
        yq .keywords[] $temp_dir/bitnami/$appFolder/$temp_version/$appFolder/Chart.yaml -r | sed 's|^|  - |g' - > $appFolder-chart-categories.txt
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
        cd $temp_dir/bitnami/$appFolder
        for versionFolder in *; do
          cat $temp_dir/bitnami/$appFolder/$versionFolder/$appFolder/values.yaml | yq . | jq '. as $input | . | paths | select(.[-1] | tostring | test("^(registry|repository|tag)$"; "ix")) | . as $path | ( $input | getpath($path) ) as $members | { "key": ( $path | join(".") ), "value": $members } ' |     jq -s 'from_entries' | sed 's/://g' - | xargs -I % echo % > $temp_dir/bitnami/$appFolder/$versionFolder/images.tmp
          tail -n +2 $temp_dir/bitnami/$appFolder/$versionFolder/images.tmp | sed '$ d' - > $temp_dir/bitnami/$appFolder/$versionFolder/images.txt
          sed 's/ .*//' $temp_dir/bitnami/$appFolder/$versionFolder/images.txt | xargs -I % echo "%" | awk 'BEGIN{FS=OFS="."}NF--' | sort -u > $temp_dir/bitnami/$appFolder/$versionFolder/paths.txt
          cat << EOF > $temp_dir/bitnami/$appFolder/$versionFolder/kbld-config.yaml
apiVersion: kbld.k14s.io/v1alpha1
kind: Config
minimumRequiredVersion: 0.29.0
searchRules:
- keyMatcher:
    path: [images, {allIndexes: true}]
EOF
          cat $temp_dir/bitnami/$appFolder/$versionFolder/$appFolder/values.yaml | yq . > $temp_dir/bitnami/$appFolder/$versionFolder/values.json
          cat $temp_dir/bitnami/$appFolder/$versionFolder/paths.txt | xargs -I % jq -c '.%.registry + "/" + .%.repository + ":" + .%.tag' $temp_dir/bitnami/$appFolder/$versionFolder/values.json > $temp_dir/bitnami/$appFolder/$versionFolder/images.list.tmp
	  grep -E '[^\/]+\.[^\/.]+\/([^\/.]+\/)?[^\/.]+(:.+)' $temp_dir/bitnami/$appFolder/$versionFolder/images.list.tmp > $temp_dir/bitnami/$appFolder/$versionFolder/images.list
          sed -i 's/^/  - /g' $temp_dir/bitnami/$appFolder/$versionFolder/images.list
	  sed -i '/  - "\/:"/d' $temp_dir/bitnami/$appFolder/$versionFolder/images.list
          # Handle Sub Charts
	  echo "Checking path $temp_dir/bitnami/$appFolder/$versionFolder/$appFolder/charts/"
	  if [[ -d "${temp_dir}/bitnami/${appFolder}/${versionFolder}/${appFolder}/charts" ]]; then
	    cd $temp_dir/bitnami/$appFolder/$versionFolder/$appFolder/charts
            ls -d * | while read d
            do
              echo $d
	      mkdir -p $temp_dir/bitnami/$appFolder/$versionFolder/$d
	      cat $temp_dir/bitnami/$appFolder/$versionFolder/$appFolder/charts/$d/values.yaml | yq . > $temp_dir/bitnami/$appFolder/$versionFolder/$d/values.json
              cat $temp_dir/bitnami/$appFolder/$versionFolder/$appFolder/charts/$d/values.yaml | yq . | jq '. as $input | . | paths | select(.[-1] | tostring | test("^(registry|repository|tag)$"; "ix")) | . as $path | ( $input | getpath($path) ) as $members | { "key": ( $path | join(".") ), "value": $members } ' |     jq -s 'from_entries' | sed 's/://g' - | xargs -I % echo % > $temp_dir/bitnami/$appFolder/$versionFolder/$d/images.tmp
              tail -n +2 $temp_dir/bitnami/$appFolder/$versionFolder/$d/images.tmp | sed '$ d' - > $temp_dir/bitnami/$appFolder/$versionFolder/$d/images.txt
              sed 's/ .*//' $temp_dir/bitnami/$appFolder/$versionFolder/$d/images.txt | xargs -I % echo "%" | awk 'BEGIN{FS=OFS="."}NF--' | sort -u > $temp_dir/bitnami/$appFolder/$versionFolder/$d/paths.txt
              cat $temp_dir/bitnami/$appFolder/$versionFolder/$d/paths.txt | xargs -I % jq -c '.%.registry + "/" + .%.repository + ":" + .%.tag' $temp_dir/bitnami/$appFolder/$versionFolder/$d/values.json > $temp_dir/bitnami/$appFolder/$versionFolder/$d/images.list.tmp
              grep -E '[^\/]+\.[^\/.]+\/([^\/.]+\/)?[^\/.]+(:.+)' $temp_dir/bitnami/$appFolder/$versionFolder/$d/images.list.tmp > $temp_dir/bitnami/$appFolder/$versionFolder/$d/images.list
              sed -i 's/^/  - /g' $temp_dir/bitnami/$appFolder/$versionFolder/$d/images.list
              sed -i '/  - "\/:"/d' $temp_dir/bitnami/$appFolder/$versionFolder/$d/images.list
	      cat $temp_dir/bitnami/$appFolder/$versionFolder/$d/images.list >> $temp_dir/bitnami/$appFolder/$versionFolder/images.list
            done
          fi
	  cd $temp_dir/bitnami/$appFolder/$versionFolder
	  sed -i '1s/^/images:\n/' $temp_dir/bitnami/$appFolder/$versionFolder/images.list
	  mkdir -p $output_dir/packages/$appFolder.bitnami.charts/$versionFolder/.imgpkg
	  mkdir -p $output_dir/packages/$appFolder.bitnami.charts/$versionFolder/config
	  kbld -f $temp_dir/bitnami/$appFolder/$versionFolder/images.list -f $temp_dir/bitnami/$appFolder/$versionFolder/kbld-config.yaml --imgpkg-lock-output $output_dir/packages/$appFolder.bitnami.charts/$versionFolder/.imgpkg/images.yml --registry-verify-certs=false
	  cp -r $temp_dir/bitnami/$appFolder/$versionFolder/$appFolder/* $output_dir/packages/$appFolder.bitnami.charts/$versionFolder/config/
          cd $temp_dir/bitnami/$appFolder/$versionFolder

          APP_VERSION=`yq .appVersion $appFolder/Chart.yaml -r`
          CHART_VERSION=`yq .version $appFolder/Chart.yaml -r`
          CHART_DESCRIPTION=`yq .description $appFolder/Chart.yaml -r`
          
          readme-generator -v $appFolder/values.yaml --metadata values-schema.json
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
	  imgpkg push -b ${registry}/${repository}/${appFolder}.bitnami.charts:${CHART_VERSION} -f $output_dir/packages/$appFolder.bitnami.charts/$versionFolder/ --registry-verify-certs=false
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
      - imgpkgBundle:
          image: ${registry}/${repository}/${appFolder}.bitnami.charts:${CHART_VERSION}
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
          cd $temp_dir/bitnami/$appFolder
        done
        cd $temp_dir/bitnami
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
      image: $registy/$repository/$package_repository_name:$package_repository_tag
  syncPeriod: $repo_sync_period
EOF

cd $output_dir
find . -type d -name config -exec rm -rf {} \;
find packages/ -type d -name .imgpkg -exec rm -rf {} \;
kbld -f ./packages/ --imgpkg-lock-output ./.imgpkg/images.yml --registry-verify-certs=false
imgpkg push -b ${registry}/${repository}/${package_repository_name} -f $output_dir --registry-verify-certs=false
echo "Done Generating the bundles!"
echo ""
echo ""
echo "#############################################################################################################"
echo "### To use this package repo in a non air gapped environment you can choose any of the following options: ###"
echo "#############################################################################################################"
echo ""
echo "1. Add as a global package to your tanzu cluster with default settings:"
echo "    tanzu package repository add $package_repository_name --url ${registry}/${repository}/${package_repository_name}:${package_repository_tag} --namespace tanzu-package-repo-global"
echo "2. Add as a global package to your tanzu cluster with custom sync interval:"
echo "    kubectl apply -n tanzu-package-repo-global -f $output_dir/package-repository-manifest.yaml"
echo ""
echo ""
echo "###############################"
echo "### Air Gapped Instructions ###"
echo "###############################"
echo ""
echo "1. Run the following command to copy all packages and images into a tar ball on your machine:"
echo "    imgpkg copy -b ${registry}/${repository}/${package_repository_name}:${package_repository_tag} --to-tar /tmp/my-repo.tar --registry-verify-certs=false"
echo "2. Import the Tar file to the airgapped environment"
echo "3. Run the following to import the artifacts to an OCI registry in your air gapped environment:"
echo "    imgpkg copy --tar /tmp/my-repo.tar --to-repo <AIR GAPPED REGISTRY>/<AIR GAPPED REPO> --registry-verify-certs=false"
echo "4. Add the repo to your cluster as per the instructions above while taking care to replace the URL with the new location"
echo ""
echo ""
echo "Enjoy!!!"
