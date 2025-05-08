cd ~/Downloads/kafka_2.13-4.0.0/config
mv tools-log4j2.yaml tools-log4j2.yaml.bak

mv connect-log4j2.yaml connect-log4j2.yaml.disabled
mv log4j2.yaml log4j2.yaml.disabled

cd ..

vim ./config/log4j2-minimal.yaml
Configuration:
  status: error
  strict: true
  monitorInterval: 0

  appenders:
    Console:
      name: STDOUT
      target: SYSTEM_OUT
      PatternLayout:
        pattern: "%d{HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n"

  loggers:
    root:
      level: info
      AppenderRef:
        - ref: STDOUT

export KAFKA_LOG4J_OPTS="-Dlog4j2.configurationFile=$PWD/config/log4j2-minimal.yaml"

# Topic 생성
bin/kafka-topics.sh \
  --bootstrap-server _:30092 \
  --create --topic test-topic --partitions 1 --replication-factor 1

# 메시지 Produce
echo '{"user":"alice","action":"login","timestamp":"2025-05-08T12:34:56Z"}' | \
  bin/kafka-console-producer.sh \
    --bootstrap-server _:30092 \
    --topic test-topic

# 메시지 Consume
bin/kafka-console-consumer.sh \
  --bootstrap-server _:30092 \
  --topic test-topic --from-beginning --max-messages 1

# 토픽 목록 확인
bin/kafka-topics.sh --bootstrap-server _:30092 --list

# 디버깅
bin/kafka-topics.sh --bootstrap-server _:30092 --list --command-config debug.properties