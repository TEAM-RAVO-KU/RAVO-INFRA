kubectl config set-context --current --namespace=logging

# ElasticSearch
helm repo add elastic https://helm.elastic.co
helm repo update

helm install elasticsearch elastic/elasticsearch \
  --namespace logging \
  --version 7.17.3 \
  -f elasticsearch-values.yaml

# Kibana
helm install kibana elastic/kibana \
  --namespace logging \
  --version 7.17.3 \
  -f kibana-values.yaml

# Fluent Bit
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update

helm install fluent-bit fluent/fluent-bit \
  --namespace logging \
  -f fluent-bit-values.yaml

kubectl config set-context --current --namespace=default