### Architecture Design
![Graduation-Project-Final Goal drawio](https://github.com/user-attachments/assets/eda24ed2-c68a-479f-a332-e0e58d7de7f7)

- Cloud Orchestration 표준인 K8s의 Helm을 통해 배포 가능하도록 구성  
- Live DB Server에 덤핑을 주기적으로 요청하여 Host Standby 상태의 별도 DB Server에 현재 데이터를 저장할 수 있도록 구현  
  - 장애 발생 시 빠르게 Host Standby DB Server로 전환 가능  
  - 데이터 일부 누락 시 Host Standby DB Server에서 차등 복구 가능
</br>

- 이와 동시에 Cold Standby 상태의 Persistent Volume에 저장 
  - Cold Standby 상태의 Storage를 통해 Peak Time이 아닐 때 더욱 적은 리소스로 복구가 가능하도록 구성  
  - Cluster 자체 장애 시 Transaction 영향을 줄여 Down Time 최소화
</br>

- Prod 환경은 K3s 단일 노드 클러스터 기반으로 구성되며, Helm을 통한 Prometheus-Grafana-Stack으로 클러스터 모니터링
- nginx Proxy 설정을 통해 외부 접근을 제어하고 안정성 증대
