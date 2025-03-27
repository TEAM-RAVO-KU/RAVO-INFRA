### Install Helm
dnf install -y git tar
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

### Install prometheus-stack
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.enabled=true \
  --set prometheus.resources.requests.cpu="100m" \
  --set prometheus.resources.requests.memory="200Mi" \
  --set grafana.resources.requests.cpu="50m" \
  --set grafana.resources.requests.memory="100Mi"
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=32000

### Grafana Secret
kubectl get secret prometheus-stack-grafana \
  -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d && echo

: << "END"
[root@k3s ~]# curl localhost:32000
<a href="/login">Found</a>.
END
