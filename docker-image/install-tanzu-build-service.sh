echo $1 | base64 -d > ./ca.crt
imgpkg pull -b $2 -o /tmp/bundle --registry-ca-cert-path ./ca.crt
ytt -f /tmp/bundle/values.yaml \
    -f /tmp/bundle/config/ \
    -f ./ca.crt \
    -v docker_repository="$3" \
    -v docker_username="$4" \
    -v docker_password="$5" \
    -v tanzunet_username="$6" \
    -v tanzunet_password="$7" \
    | kbld -f /tmp/bundle/.imgpkg/images.yml -f- \
    | kapp deploy -a tanzu-build-service -f- -y
