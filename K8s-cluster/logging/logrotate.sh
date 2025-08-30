kubectl port-forward --namespace logging svc/elasticsearch-master 9200:9200

curl -X PUT "http://localhost:9200/_ilm/policy/k8s_log_policy" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_age": "1d",
            "max_size": "25gb"
          }
        }
      },
      "delete": {
        "min_age": "7d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
'

curl -X PUT "http://localhost:9200/_template/k8s_log_template" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["k8s-log-*"],
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0,
    "index.lifecycle.name": "k8s_log_policy",
    "index.lifecycle.rollover_alias": "k8s-log"
  }
}
'