# [TroubleShooting]
# Received FIND_COORDINATOR response … errorCode=15  
# org.apache.kafka.common.errors.CoordinatorNotAvailableException: The coordinator is not available.

# __consumer_offsets 토픽 수동 생성
./kafka_2.13-3.5.1/bin/kafka-topics.sh \
  --bootstrap-server _:9095 \
  --create --topic __consumer_offsets \
  --partitions 50 \
  --replication-factor 1 \
  --config cleanup.policy=compact \
  --config segment.bytes=104857600
  
# 토픽 생성 확인
./kafka_2.13-3.5.1/bin/kafka-topics.sh \
  --bootstrap-server _:9095 \
  --describe --topic __consumer_offsets
  << "END"
  opic: __consumer_offsets       TopicId: L-74F-tWT1-iRbagWIKsJw PartitionCount: 50      ReplicationFactor: 1    Configs: cleanup.policy=compact,segment.bytes=104857600
        Topic: __consumer_offsets       Partition: 0    Leader: 100     Replicas: 100   Isr: 100
        Topic: __consumer_offsets       Partition: 1    Leader: 100     Replicas: 100   Isr: 100
        ...
  : "END"