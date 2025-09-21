./kafka_2.13-3.5.1/bin/kafka-topics.sh \
    --bootstrap-server _:9095 \
    --list --command-config ./kafka-client.properties
<< "OUTPUT"
debezium-offsets
debezium-schema-history
ravo_db
ravo_db.ravo_db.integrity_data
test-topic
OUTPUT



### [Troubleshooting]
# debezium Pod 삭제 이후 재배포 시
# "Could not find first log file name in binary log index file Error code: 1236; SQLSTATE: HY000"
# MySQL의 바이너리 로그 인덱스에서 지정된 첫 번째 로그 파일을 찾을 수 없어
# Debezium이 읽기를 못하고 실패한 오류
# 1. offsets 토픽 삭제
./kafka_2.13-3.5.1/bin/kafka-topics.sh \
  --bootstrap-server _:9095 \
  --delete \
  --topic debezium-offsets
# 2. schema-history 토픽 삭제
./kafka_2.13-3.5.1/bin/kafka-topics.sh \
  --bootstrap-server _:9095 \
  --delete \
  --topic debezium-schema-history
# 3. debezium-offsets를 cleanup.policy=compact로 재생성
./kafka_2.13-3.5.1/bin/kafka-topics.sh \
  --bootstrap-server _:9095 \
  --create \
  --topic debezium-offsets \
  --partitions 1 \
  --replication-factor 1 \
  --config cleanup.policy=compact
# 4. debezium 재배포
k apply -f debezium.yaml


<< "SQL"
INSERT INTO integrity_data(data) VALUES('CDC Test');
SQL

<< "debezium-server-log"
{"timestamp":"2025-05-19T12:26:40.061521368Z","sequence":561,"loggerClassName":"org.slf4j.impl.Slf4jLogger","loggerName":"io.debezium.connector.binlog.BinlogStreamingChangeEventSource","level":"INFO","message":"Keepalive thread is running","threadName":"debezium-mysqlconnector-ravo_db-change-event-source-coordinator","threadId":43,"mdc":{"dbz.taskId":"0","dbz.connectorName":"ravo_db","dbz.connectorType":"MySQL","dbz.connectorContext":"streaming"},"ndc":"","hostName":"debezium-server-6f86cb7d88-shx44","processName":"/usr/lib/jvm/java-21-openjdk-21.0.7.0.6-1.el8.x86_64/bin/java","processId":1}
{"timestamp":"2025-05-19T12:29:34.239309264Z","sequence":562,"loggerClassName":"org.slf4j.impl.Slf4jLogger","loggerName":"io.debezium.connector.common.BaseSourceTask","level":"INFO","message":"4 records sent during previous 00:02:57.355, last recorded offset of {server=ravo_db} partition is {ts_sec=1747657773, file=mysql-bin.000007, pos=1002, row=1, server_id=223344, event=2}","threadName":"pool-8-thread-1","threadId":38,"mdc":{},"ndc":"","hostName":"debezium-server-6f86cb7d88-shx44","processName":"/usr/lib/jvm/java-21-openjdk-21.0.7.0.6-1.el8.x86_64/bin/java","processId":1}
debezium-server-log

./kafka_2.13-3.5.1/bin/kafka-console-consumer.sh \
  --bootstrap-server _:9095 \
  --topic ravo_db.ravo_db.integrity_data --from-beginning --partition 0
<< "OUTPUT"
{"schema":{"type":"struct","fields":[{"type":"struct","fields":[{"type":"int64","optional":false,"field":"id"},{"type":"string","optional":true,"field":"data"},{"type":"int64","optional":true,"name":"io.debezium.time.Timestamp","version":1,"default":0,"field":"checked_at"}],"optional":true,"name":"ravo_db.ravo_db.integrity_data.Value","field":"before"},{"type":"struct","fields":[{"type":"int64","optional":false,"field":"id"},{"type":"string","optional":true,"field":"data"},{"type":"int64","optional":true,"name":"io.debezium.time.Timestamp","version":1,"default":0,"field":"checked_at"}],"optional":true,"name":"ravo_db.ravo_db.integrity_data.Value","field":"after"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"version"},{"type":"string","optional":false,"field":"connector"},{"type":"string","optional":false,"field":"name"},{"type":"int64","optional":false,"field":"ts_ms"},{"type":"string","optional":true,"name":"io.debezium.data.Enum","version":1,"parameters":{"allowed":"true,first,first_in_data_collection,last_in_data_collection,last,false,incremental"},"default":"false","field":"snapshot"},{"type":"string","optional":false,"field":"db"},{"type":"string","optional":true,"field":"sequence"},{"type":"int64","optional":true,"field":"ts_us"},{"type":"int64","optional":true,"field":"ts_ns"},{"type":"string","optional":true,"field":"table"},{"type":"int64","optional":false,"field":"server_id"},{"type":"string","optional":true,"field":"gtid"},{"type":"string","optional":false,"field":"file"},{"type":"int64","optional":false,"field":"pos"},{"type":"int32","optional":false,"field":"row"},{"type":"int64","optional":true,"field":"thread"},{"type":"string","optional":true,"field":"query"}],"optional":false,"name":"io.debezium.connector.mysql.Source","version":1,"field":"source"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"id"},{"type":"int64","optional":false,"field":"total_order"},{"type":"int64","optional":false,"field":"data_collection_order"}],"optional":true,"name":"event.block","version":1,"field":"transaction"},{"type":"string","optional":false,"field":"op"},{"type":"int64","optional":true,"field":"ts_ms"},{"type":"int64","optional":true,"field":"ts_us"},{"type":"int64","optional":true,"field":"ts_ns"}],"optional":false,"name":"ravo_db.ravo_db.integrity_data.Envelope","version":2},"payload":{"before":null,"after":{"id":1,"data":"초기 데이터","checked_at":1747051999000},"source":{"version":"3.1.1.Final","connector":"mysql","name":"ravo_db","ts_ms":1747657597000,"snapshot":"last","db":"ravo_db","sequence":null,"ts_us":1747657597000000,"ts_ns":1747657597000000000,"table":"integrity_data","server_id":0,"gtid":null,"file":"mysql-bin.000007","pos":923,"row":0,"thread":null,"query":null},"transaction":null,"op":"r","ts_ms":1747657597974,"ts_us":1747657597974015,"ts_ns":1747657597974015252}}
{"schema":{"type":"struct","fields":[{"type":"struct","fields":[{"type":"int64","optional":false,"field":"id"},{"type":"string","optional":true,"field":"data"},{"type":"int64","optional":true,"name":"io.debezium.time.Timestamp","version":1,"default":0,"field":"checked_at"}],"optional":true,"name":"ravo_db.ravo_db.integrity_data.Value","field":"before"},{"type":"struct","fields":[{"type":"int64","optional":false,"field":"id"},{"type":"string","optional":true,"field":"data"},{"type":"int64","optional":true,"name":"io.debezium.time.Timestamp","version":1,"default":0,"field":"checked_at"}],"optional":true,"name":"ravo_db.ravo_db.integrity_data.Value","field":"after"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"version"},{"type":"string","optional":false,"field":"connector"},{"type":"string","optional":false,"field":"name"},{"type":"int64","optional":false,"field":"ts_ms"},{"type":"string","optional":true,"name":"io.debezium.data.Enum","version":1,"parameters":{"allowed":"true,first,first_in_data_collection,last_in_data_collection,last,false,incremental"},"default":"false","field":"snapshot"},{"type":"string","optional":false,"field":"db"},{"type":"string","optional":true,"field":"sequence"},{"type":"int64","optional":true,"field":"ts_us"},{"type":"int64","optional":true,"field":"ts_ns"},{"type":"string","optional":true,"field":"table"},{"type":"int64","optional":false,"field":"server_id"},{"type":"string","optional":true,"field":"gtid"},{"type":"string","optional":false,"field":"file"},{"type":"int64","optional":false,"field":"pos"},{"type":"int32","optional":false,"field":"row"},{"type":"int64","optional":true,"field":"thread"},{"type":"string","optional":true,"field":"query"}],"optional":false,"name":"io.debezium.connector.mysql.Source","version":1,"field":"source"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"id"},{"type":"int64","optional":false,"field":"total_order"},{"type":"int64","optional":false,"field":"data_collection_order"}],"optional":true,"name":"event.block","version":1,"field":"transaction"},{"type":"string","optional":false,"field":"op"},{"type":"int64","optional":true,"field":"ts_ms"},{"type":"int64","optional":true,"field":"ts_us"},{"type":"int64","optional":true,"field":"ts_ns"}],"optional":false,"name":"ravo_db.ravo_db.integrity_data.Envelope","version":2},"payload":{"before":null,"after":{"id":2,"data":"CDC Test","checked_at":1747657773000},"source":{"version":"3.1.1.Final","connector":"mysql","name":"ravo_db","ts_ms":1747657773000,"snapshot":"false","db":"ravo_db","sequence":null,"ts_us":1747657773000000,"ts_ns":1747657773000000000,"table":"integrity_data","server_id":223344,"gtid":null,"file":"mysql-bin.000007","pos":1161,"row":0,"thread":815,"query":null},"transaction":null,"op":"c","ts_ms":1747657774093,"ts_us":1747657774093475,"ts_ns":1747657774093475276}}
{"schema":{"type":"struct","fields":[{"type":"struct","fields":[{"type":"int64","optional":false,"field":"id"},{"type":"string","optional":true,"field":"data"},{"type":"int64","optional":true,"name":"io.debezium.time.Timestamp","version":1,"default":0,"field":"checked_at"}],"optional":true,"name":"ravo_db.ravo_db.integrity_data.Value","field":"before"},{"type":"struct","fields":[{"type":"int64","optional":false,"field":"id"},{"type":"string","optional":true,"field":"data"},{"type":"int64","optional":true,"name":"io.debezium.time.Timestamp","version":1,"default":0,"field":"checked_at"}],"optional":true,"name":"ravo_db.ravo_db.integrity_data.Value","field":"after"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"version"},{"type":"string","optional":false,"field":"connector"},{"type":"string","optional":false,"field":"name"},{"type":"int64","optional":false,"field":"ts_ms"},{"type":"string","optional":true,"name":"io.debezium.data.Enum","version":1,"parameters":{"allowed":"true,first,first_in_data_collection,last_in_data_collection,last,false,incremental"},"default":"false","field":"snapshot"},{"type":"string","optional":false,"field":"db"},{"type":"string","optional":true,"field":"sequence"},{"type":"int64","optional":true,"field":"ts_us"},{"type":"int64","optional":true,"field":"ts_ns"},{"type":"string","optional":true,"field":"table"},{"type":"int64","optional":false,"field":"server_id"},{"type":"string","optional":true,"field":"gtid"},{"type":"string","optional":false,"field":"file"},{"type":"int64","optional":false,"field":"pos"},{"type":"int32","optional":false,"field":"row"},{"type":"int64","optional":true,"field":"thread"},{"type":"string","optional":true,"field":"query"}],"optional":false,"name":"io.debezium.connector.mysql.Source","version":1,"field":"source"},{"type":"struct","fields":[{"type":"string","optional":false,"field":"id"},{"type":"int64","optional":false,"field":"total_order"},{"type":"int64","optional":false,"field":"data_collection_order"}],"optional":true,"name":"event.block","version":1,"field":"transaction"},{"type":"string","optional":false,"field":"op"},{"type":"int64","optional":true,"field":"ts_ms"},{"type":"int64","optional":true,"field":"ts_us"},{"type":"int64","optional":true,"field":"ts_ns"}],"optional":false,"name":"ravo_db.ravo_db.integrity_data.Envelope","version":2},"payload":{"before":null,"after":{"id":3,"data":"CDC Test","checked_at":1747657899000},"source":{"version":"3.1.1.Final","connector":"mysql","name":"ravo_db","ts_ms":1747657899000,"snapshot":"false","db":"ravo_db","sequence":null,"ts_us":1747657899000000,"ts_ns":1747657899000000000,"table":"integrity_data","server_id":223344,"gtid":null,"file":"mysql-bin.000007","pos":1489,"row":0,"thread":815,"query":null},"transaction":null,"op":"c","ts_ms":1747657899418,"ts_us":1747657899418159,"ts_ns":1747657899418159799}}
OUTPUT
