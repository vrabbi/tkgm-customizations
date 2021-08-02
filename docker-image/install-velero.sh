sed -i "s/<S3_ACCESS_KEY>/$4/g" ./velero-creds
sed -i "s/<S3_SECRET_KEY>/$5/g" ./velero-creds
velero install --provider aws --plugins "velero/velero-plugin-for-aws:v1.1.0" --bucket $1 --secret-file ./velero-creds --backup-location-config "region=$2,s3ForcePathStyle=true,s3Url=$3" --snapshot-location-config region="default"
velero plugin add vsphereveleroplugin/velero-plugin-for-vsphere:1.1.0
velero snapshot-location create vsl-vsphere --provider velero.io/vsphere
