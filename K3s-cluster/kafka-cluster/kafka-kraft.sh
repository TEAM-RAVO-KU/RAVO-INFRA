kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml

[root@master kafka]# k get storageclass
NAME         PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  50s

helm install kafka bitnami/kafka \
  --version 27.1.2 \
  --namespace kafka \
  -f values.yaml \
  --set kraft.replicaCount=1 \
  --set image.tag=3.7.0 \
  --set volumePermissions.enabled=false

########################
# 1. Helm 릴리스 삭제
helm uninstall kafka --namespace kafka

# 2. 남아있는 모든 Kafka PVC 삭제
kubectl delete pvc -n kafka -l app.kubernetes.io/instance=kafka