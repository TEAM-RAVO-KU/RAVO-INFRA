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

# kafka-values에 대한 변경사항 발생시 helm upgrade
helm upgrade kafka bitnami/kafka -n kafka -f kafka-values.yaml

# 저사양 디스크 + 512Mi heap이면 Controller 세팅에 1~3분, 간혹 5분 이상 소요되가 때문에
# kafka-controller-0의 로그를 추적하여 배포 상태 확인
k logs kafka-controller-0 -n kafka -f

# kafka-broker PVC에 이전 메타데이터가 남아 있어 포맷 단계에서
# “이미 포맷됨”으로 실패‑종료되는 상황, 브로커 PVC만 비우고 다시 기동
kubectl delete pod -n kafka kafka-broker-0
kubectl delete pvc -n kafka data-kafka-broker-0
# StatefulSet이 새 PVC를 만들며 자동으로 새 Pod 생성
watch -n5 'kubectl get pods -n kafka'

### StatyefulSet 수동 스케일링 방안
# 브로커 중지
kubectl scale sts kafka-broker -n kafka --replicas=0
# PVC 삭제
kubectl delete pvc -n kafka data-kafka-broker-0
# 다시 1로 스케일 업
# 새 PVC + 새 Pod
kubectl scale sts kafka-broker -n kafka --replicas=1

# Helm을 통해 kafka-exporter 
# ServiceMonitor 생성 시 release: prometheus-stack 라벨이
# kube‑prometheus‑stack 와 일치해야 Prometheus 가 자동적으로 인식
helm install kafka-exp prometheus-community/prometheus-kafka-exporter \
  -n kafka -f kafka-exp-values.yaml