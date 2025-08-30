kubectl config set-context --current --namespace=logging

helm repo add elastic https://helm.elastic.co
helm repo update

helm install elasticsearch elastic/elasticsearch \
  --namespace logging \
  --version 7.17.3 \
  -f elasticsearch-values.yaml

helm install kibana elastic/kibana \
  --namespace logging \
  --version 7.17.3 \
  -f kibana-values.yaml

kubectl config set-context --current --namespace=default