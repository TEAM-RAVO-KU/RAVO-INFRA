# Bitnami는 VMware Tanzu에서 관리하는 오픈소스 애플리케이션 카탈로그로,
# 다양한 OSS를 보안과 호환성 측면에서 검증된 컨테이너 이미지·가상머신·Helm 차트 형태로 바로 동작 가능한 패키지로 제공

# Bitnami의 퍼블릭 Helm 차트 저장소를 등록하면
# bitnami/kafka 차트를 통해 Kafka 클러스터를 위한 Kubernetes 리소스 템플릿과 권장 설정값을 자동으로 가져와 간편하게 배포·관리 가능
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# kafka를 위한 네임스페이스 생성
kubectl create ns kafka

# Bitnami가 제공하는 Kafka Helm 차트를 K3s 클러스터에 kafka라는 이름으로 설치하되,
# 별도 값 파일(kafka-values.yaml)을 적용하여 kafka 네임스페이스에 배포

# 브로커 내부 advertised listener는 externalAccess.autoDiscovery 로 자동 주입
# -f kafka-values.yaml (--values kafka-values.yaml) 기본 차트 설정값을 덮어쓸 사용자 정의 값 파일 지정
helm install kafka bitnami/kafka -n kafka -f kafka-values.yaml

# 저사양 디스크 + 512Mi heap이면 Controller 세팅에 1~3분, 간혹 5분 이상 소요되가 때문에
# kafka-controller-0의 로그를 추적하여 배포 상태 확인
k logs kafka-controller-0 -n kafka -f

# Helm을 통해 kafka-exporter 
# ServiceMonitor 생성 시 release: prometheus-stack 라벨이
# kube‑prometheus‑stack 와 일치해야 Prometheus 가 자동적으로 인식
helm install kafka-exp prometheus-community/prometheus-kafka-exporter \
  -n kafka -f kafka-exp-values.yaml



### [PVC 관련 트러블슈팅]
# 네임스페이스를 kafka로 변경
kubectl config set-context --current --namespace=kafka

# kafka-broker PVC에 이전 메타데이터가 남아 있어 포맷 단계에서
# “이미 포맷됨”으로 실패‑종료되는 상황, 브로커 PVC만 비우고 다시 기동
kubectl delete pod -n kafka kafka-broker-0
kubectl delete pvc -n kafka data-kafka-broker-0
# StatefulSet이 새 PVC를 만들며 자동으로 새 Pod 생성
watch -n5 'kubectl get pods -n kafka'



### [StatefulSet 수동 스케일링 방안]
# kafka-broker StatefulSet의 ContainerPort 확인
kubectl get sts kafka-broker -o jsonpath="{.spec.template.spec.containers[0].ports}"
# 브로커 중지
kubectl scale sts kafka-broker -n kafka --replicas=0
# PVC 삭제
kubectl delete pvc -n kafka data-kafka-broker-0
# 다시 1로 스케일 업
# 새 PVC + 새 Pod
kubectl scale sts kafka-broker -n kafka --replicas=1

# StatefulSet 삭제
kubectl delete sts kafka-broker

# StatefulSet만 재배포
helm template kafka bitnami/kafka \
  -n kafka -f kafka-values.yaml \
  --show-only templates/broker/statefulset.yaml \
| kubectl apply -f -

# kafka-broker-0 내부 로그 파일 전부 확인
kubectl exec kafka-broker-0 -c kafka -- bash -c 'sudo find / -name "*.log"'
# 컨테이너 안에 Kafka 자체 로그가 전혀 안 만들어지고 있다 -> 커널이 OOM (메모리 부족) 으로 Java 프로세스를 바로 kill 한 경우
# 최근 종료 상태 확인 (exitCode 137 = OOM Kill)
kubectl get pod kafka-broker-0 -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
kubectl get pod kafka-broker-0 -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}{"\n"}'
# 노드 dmesg 에 OOM 흔적 보기(노드에서)
sudo dmesg | grep -i -E 'killed process.*java|oom'
: << "END"  
[857400.388193] oom-kill:constraint=CONSTRAINT_MEMCG,nodemask=(null),cpuset=cri-containerd-b0a75cb93a762d493de09588e0dae48e0efd946e6c8c7c5c8362031834091f20.scope,mems_allowed=0,oom_memcg=/kubepods.slice/kubepods-burstable.slice/kubepods-burstable-pod03b7fe6c_4c5e_40e5_a17d_e82f148d42f1.slice/cri-containerd-b0a75cb93a762d493de09588e0dae48e0efd946e6c8c7c5c8362031834091f20.scope,task_memcg=/kubepods.slice/kubepods-burstable.slice/kubepods-burstable-pod03b7fe6c_4c5e_40e5_a17d_e82f148d42f1.slice/cri-containerd-b0a75cb93a762d493de09588e0dae48e0efd946e6c8c7c5c8362031834091f20.scope,task=mysqld,pid=796205,uid=999
[857400.388400] Memory cgroup out of memory: Killed process 796205 (mysqld) total-vm:2403480kB, anon-rss:521000kB, file-rss:36352kB, shmem-rss:0kB, UID:999 pgtables:1412kB oom_score_adj:961
[857400.388528] Tasks in /kubepods.slice/kubepods-burstable.slice/kubepods-burstable-pod03b7fe6c_4c5e_40e5_a17d_e82f148d42f1.slice/cri-containerd-b0a75cb93a762d493de09588e0dae48e0efd946e6c8c7c5c8362031834091f20.scope are going to be killed due to memory.oom.group set
[857400.388756] Memory cgroup out of memory: Killed process 796205 (mysqld) total-vm:2403480kB, anon-rss:521000kB, file-rss:36352kB, shmem-rss:0kB, UID:999 pgtables:1412kB oom_score_adj:961
END
# Kafka 브로커는 최소 1 Gi 이상(Heap + 오버헤드)을 계속 요구하므로 2 분마다 GC/OOM으로 Killed
# Zookeper 모드로 전환하여 메모리를 추가적으로 확보

# kafka-values에 대한 변경사항 발생시 helm upgrade
helm upgrade kafka bitnami/kafka -n kafka -f kafka-values.yaml



### [버전 다운그레이드]
# bitnami/kafka 버전 확인
helm search repo bitnami/kafka --versions

# kafka Helm 차트 삭제
helm uninstall kafka -n kafka

# PVC 삭제
k delete pvc data-kafka-broker-0
k delete pvc data-kafka-zookeeper-0

# 메모리 절약과 ZK 모드를 사용하기 위해 28.3.0으로 다운그레이드하여 설치
helm install kafka bitnami/kafka \
  --version 28.3.0 \
  -f kafka-values.yaml \
  -n kafka

k logs -f -n kafka kafka-broker-0



### [Broker SASL HandShake 트러블슈팅]
# kafka-broker 환경변수
kubectl -n kafka exec kafka-broker-0 -- \
  grep -E '^(listeners|advertised\.listeners|listener\.security\.protocol\.map)' \
  /opt/bitnami/kafka/config/server.properties

: << "END"
# 아래가 정상 출력 (SASL 비활성화를 위해 덮어쓴 상태, EXTERNAL에 호스트의 공인 IP 설정)
Defaulted container "kafka" out of: kafka, kafka-init (init)
listeners=CLIENT://:9092,INTERNAL://:9094,EXTERNAL://:9095
listener.security.protocol.map=CLIENT:SASL_PLAINTEXT,INTERNAL:SASL_PLAINTEXT,EXTERNAL:SASL_PLAINTEXT
advertised.listeners=CLIENT://kafka-broker-0.kafka-broker-headless.kafka.svc.cluster.local:9092,INTERNAL://kafka-broker-0.kafka-broker-headless.kafka.svc.cluster.local:9094,EXTERNAL://<Host Public IP>:30092
listener.security.protocol.map=CLIENT:PLAINTEXT,INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
END

kubectl -n kafka exec kafka-broker-0 -- printenv

# 실제로 해당 NodePort에 대한 패킷 캡처
sudo tcpdump -nn -i any port 30092 -c 30 &

# broker 내부에서 직접 Topic 생성
kubectl -n kafka exec -it kafka-broker-0 -- \
  /opt/bitnami/kafka/bin/kafka-topics.sh \
    --bootstrap-server localhost:9092 --create \
    --topic quick --partitions 1 --replication-factor 1

# kafka 컨테이너(=target=kafka) 안에 netshoot 디버그 컨테이너 붙이기
kubectl debug kafka-broker-0 -n kafka \
  --image=nicolaka/netshoot \
  --target=kafka-broker-0 -it

# 프롬프트가 바뀌면 내부에서
ss -ltnp
netstat -tnlp




### [배포 완료 후 Secret 요구 시]
# clusterId를 새로 생성
export CLUSTER_ID=$(uuidgen)

# helm upgrade
helm upgrade kafka bitnami/kafka -n kafka -f kafka-values.yaml \
  --set existingPasswordSecret=kafka-user-passwords \
  --set clusterId=$CLUSTER_ID


### [kafka-exp 트러블 슈팅]
helm uninstall kafka-exp -n kafka

# 값 재사용 없이 upgrade
helm upgrade --install kafka-exp prometheus-community/prometheus-kafka-exporter \
  -n kafka -f kafka-exp-values.yaml --reset-values

# kafka-exp Manifest 값을 가져와 검증
helm -n kafka get manifest kafka-exp | grep -- --kafka.server

# 버전 적용이 되지 않는 문제를 해결하기 위해 helm 릴리즈 조정
helm -n kafka uninstall kafka-exp

# 로컬 차트 캐시 업데이트
helm repo update
helm repo remove prometheus-community
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update



### [ERROR: org.apache.kafka.common.errors.DisconnectException 트러블슈팅팅]
kubectl -n kafka get svc kafka-broker-0-external -o yaml

: << "END"
# externalTrafficPolicy Cluster 확인인
spec:
  clusterIP: 10.43.174.133
  clusterIPs:
  - 10.43.174.133
  externalTrafficPolicy: Cluster
END