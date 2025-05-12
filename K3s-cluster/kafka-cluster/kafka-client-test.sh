cd ~/Downloads/kafka_2.13-4.0.0

# ~/kafka-client.properties
# Increase timeout to 2 minutes (120 000 ms)
default.api.timeout.ms=120000
request.timeout.ms=120000

### Produce, Consume 시 Topic이 우선 1개라는 점 주의
# Topic 생성
bin/kafka-topics.sh \
  --bootstrap-server _:9095  \
  --create --topic test-topic --partitions 1 --replication-factor 1

# 메시지 Produce
echo '{"user":"alice","action":"login","timestamp":"2025-05-08T12:34:56Z"}' | \
  bin/kafka-console-producer.sh \
    --bootstrap-server _:9095  \
    --topic test-topic

# 메시지 Consume
bin/kafka-console-consumer.sh \
  --bootstrap-server _:9095  \
  --topic test-topic --from-beginning --partition 0

# 토픽 목록 확인
bin/kafka-topics.sh --bootstrap-server _:9095  --list

# 디버깅
bin/kafka-topics.sh --bootstrap-server _:9095  --list --command-config debug.properties