# https://guide.ncloud-docs.com/docs/k8s-iam-auth-ncp-iam-authenticator
# Win
curl -o ncp-iam-authenticator.exe -L https://github.com/NaverCloudPlatform/ncp-iam-authenticator/releases/latest/download/ncp-iam-authenticator_windows_amd64.exe
Get-FileHash ncp-iam-authenticator.exe
curl -o ncp-iam-authenticator.sha256 -L https://github.com/NaverCloudPlatform/ncp-iam-authenticator/releases/latest/download/ncp-iam-authenticator_SHA256SUMS

ncp-iam-authenticator help

# https://guide.ncloud-docs.com/docs/k8s-iam-auth-kubeconfig
export NCLOUD_ACCESS_KEY=ACCESSKEYIDACCESSKEY
export NCLOUD_SECRET_KEY=SECRETACCESSKEYSECRETACCESSKEYSECRETACCE
export NCLOUD_API_GW=https://ncloud.apigw.ntruss.com

cat ~/.ncloud/configure

ncp-iam-authenticator update-kubeconfig --region <region-code> --clusterUuid <cluster-uuid>

# kubectl
lenovo@DESKTOP-KS3RBUH MINGW64 ~/k-paas
$ kubectl get node
NAME                     STATUS   ROLES    AGE    VERSION
contest-18-node-w-7f0d   Ready    <none>   105d   v1.31.7