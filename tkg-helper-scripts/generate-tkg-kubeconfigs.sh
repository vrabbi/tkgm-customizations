mkdir per-cluster
mkdir all-clusters
mkdir per-cluster/no-browser
mkdir per-cluster/with-browser
mkdir per-cluster/admin

cd per-cluster/admin
tanzu cluster list -o json | jq -r .[].name | while read i; do tanzu cluster kubeconfig get --admin $i --export-file $i-admin-kubeconfig; done
cd ..
cd with-browser
unset TANZU_CLI_PINNIPED_AUTH_LOGIN_SKIP_BROWSER
tanzu cluster list -o json | jq -r .[].name | while read i; do tanzu cluster kubeconfig get $i --export-file $i-with-browser-kubeconfig; done
cd ..
cd no-browser
tanzu cluster list -o json | jq -r .[].name | while read i; do TANZU_CLI_PINNIPED_AUTH_LOGIN_SKIP_BROWSER=true tanzu cluster kubeconfig get $i --export-file $i-no-browser-kubeconfig; done
cd ../../
cd all-clusters/

tanzu cluster list -o json | jq -r .[].name | while read i; do tanzu cluster kubeconfig get --admin $i --export-file all-clusters-admin-kubeconfig; done
unset TANZU_CLI_PINNIPED_AUTH_LOGIN_SKIP_BROWSER
tanzu cluster list -o json | jq -r .[].name | while read i; do tanzu cluster kubeconfig get $i --export-file all-clusters-with-browser-kubeconfig; done
tanzu cluster list -o json | jq -r .[].name | while read i; do TANZU_CLI_PINNIPED_AUTH_LOGIN_SKIP_BROWSER=true tanzu cluster kubeconfig get $i --export-file all-clusters-no-browser-kubeconfig; done
