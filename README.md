### Architecture Design

<img width="642" height="530" alt="그림" src="https://github.com/user-attachments/assets/365a91e8-c91e-432a-8844-0cf528e6eb81" /> </br>

자동화 DB Application DR 솔루션을 구현하는 것을 목표로 하고 있기에 Naver Cloud Platform의 Kubernetes Cluster와 On-Premise Kuberntes Cluster 두 개의 물리적, 논리적으로 분리된 클러스터를 사용하여 아키텍처를 구성하였습니다. </br>
On-Premise 클러스터의 경우 홈 서버 형태로 200일 이상 정상 운영되고 있습니다. </br> </br>

RAVO는 기존에 이미 활용하고 있는 서비스의 Active DB를 그대로 유지하면서 추가되어 기능하도록 개발되었으며, Active DB의 위치는 통신이 도달 가능하다면 RAVO 솔루션과의 물리적 혹은 논리적 독립 여부와 관계없이 정상적으로 기능하도록 개발되었습니다.

### K-PaaS NCP Kubernetes Node 상 구성 요소 및 역할

**[RAVO-MANAGER]**
* Spring Thymeleaf 기반 웹 애플리케이션입니다.
* /client에서는 RAVO의 시나리오를 검증하기 위해 K-PaaS 기반 금융권 서비스의 입출금/송금 기능을 구현하였습니다.
* /client에서 Active DB 장애 상황을 발생시킬 수 있습니다.
* /dashboard에서는 NCP내 Active DB와 On-Prem내 Standby DB의 상태와 메트릭 및 Binlog와 데이터 일치율을 시각화하였습니다.
* 추후 Standby DB Proxy Service를 조작할 수 있게 하는 등의 기능을 추가할 예정입니다.

**[MySQL Active]**
* 기존에 활용하고 있는 것으로 가정한 MySQL 애플리케이션입니다.
* 타 서비스의 DB에 RAVO가 정상적으로 통합될 수 있습니다.
* MySQL Active Service: Failover 시 Patch되는 Service입니다.
* MySQL Active Direct Service: Patch되지 않는 Service 입니다.

**[MySQL Standby Proxy]**
* nginx Stream을 통해 On-Prem의 Standby DB에 연결 가능한 Proxy Service와 nginx Deployment입니다.

**[RAVO-AGENT]**
* 3개의 컨테이너로 이루어진 RAVO의 핵심 워크로드입니다.
* Active DB에 대한 Failover와 Service Patch를 통한 Recovery를 수행하여 RAVO의 핵심 기능 동작을 가능하게 합니다.

---

### On-Premise Kubernetes Cluster 상 구성 요소 및 역할

**[Debezium Server]**
* Active DB에 대해 CDC를 수행하여 Live Sync를 위한 Kafka Topic의 Message를 Produce합니다.
* Keep-Alive 기능과 DB 재시도 로직을 추가하여 ActiveDB의 Idle 상태와 장애 상황에 대비하였습니다.

**[Kafka Cluster]**
* RAVO-SERVER가 Live Sync를 위해 구독하는 메시지 큐입니다.

**[RAVO-SERVER]**
* Kafka의 CDC Topic을 구독하여 실시간으로 Active DB의 쿼리를 Standby DB에 적용해 Live Sync를 수행합니다.
* 주기적으로 Active DB에 대한 헬스체킹을 수행합니다.
* Active DB Down 시 Failover된 Standby DB로의 쿼리를 GTID를 활용해 추적하여 기록하고 Active DB가 다시 UP 되었을 때 Standby DB의 변경 사항을 역으로 Active DB에 적용합니다. 이후 Active Service를 Patch하는 [RAVO-AGENT] API를 호출합니다.

**[RAVO Persistent Volume]**
* 일 1회 RAVO-SERVER가 Dump Backup을 수행하는 볼륨입니다.
* 물리적으로 분리되며 복구 로직까지 지닌 소산 백업 형태입니다.

**[MySQL Standby]**
* 빈 상태로 새롭게 배포될 MySQL 애플리케이션입니다.

---
