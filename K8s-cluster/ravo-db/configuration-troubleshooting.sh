############ [Debezium]
# debezium Pod 삭제 이후 재배포 시
# "Could not find first log file name in binary log index file Error code: 1236; SQLSTATE: HY000"
# MySQL의 바이너리 로그 인덱스에서 지정된 첫 번째 로그 파일을 찾을 수 없어
# Debezium이 읽기를 못하고 실패한 오류
# 1. offsets 토픽 삭제
./kafka_2.13-3.5.1/bin/kafka-topics.sh \
  --bootstrap-server _:9095 \
  --delete \
  --topic debezium-offsets \
# 2. schema-history 토픽 삭제
./kafka_2.13-3.5.1/bin/kafka-topics.sh \
  --bootstrap-server _:9095 \
  --delete \
  --topic debezium-schema-history \
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

############ [Active DB]
kubectl exec -it mysql-active-f648c7bf9-tjrcx -- /bin/bash

# Access denied for user 'debezium'@'10.244.19.19' (using password: YES)
CREATE USER IF NOT EXISTS 'debezium'@'%' IDENTIFIED BY 'dbz!pass';
GRANT REPLICATION SLAVE, REPLICATION CLIENT, SELECT, RELOAD, SHOW DATABASES ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;

# Active DB에서 실행 (만약 ravo_db 매니페스트 때문에 누락되었을 시)
CREATE DATABASE ravo_db;

############ [Standby DB]
kubectl exec -it mysql-standby-795dc5584c-s6khj -- /bin/bash

# GTID 적용 확인
bash-5.1# cat /etc/mysql/conf.d/custom.cnf
[mysqld]
gtid_mode=ON
enforce_gtid_consistency=ON

mysql -u root -p
# 서버가 시작된 이후 실행된 모든 트랜잭션의 GTID 집합을 보기 위해 gtid_executed 시스템 변수를 확인

# 아래 부분은 트랜잭션이 처음 시작된 서버의 고유 ID(UUID)
# 1-8: 1번부터 8번까지의 트랜잭션이 연속으로 모두 실행되었다는 의미
# 만약 트랜잭션이 하나만 있었다면 :9처럼 표시되고, 중간에 빠진 번호가 있다면 :1-5, 9와 같이 쉼표로 구분되어 표시
# 고유 ID가 bc720bb3...로 시작하는 서버에서 만들어진 1번부터 8번까지의 트랜잭션이 이 서버에 모두 적용되었다는 의미

SHOW GLOBAL VARIABLES LIKE 'gtid_executed';
+---------------+------------------------------------------+
| Variable_name | Value                                    |
+---------------+------------------------------------------+
| gtid_executed | bc720bb3-8df7-11f0-b1f3-f295eb9df264:1-8 |
+---------------+------------------------------------------+
1 row in set (0.005 sec)

SHOW BINARY LOGS;
+---------------+-----------+-----------+
| Log_name      | File_size | Encrypted |
+---------------+-----------+-----------+
| binlog.000001 |   2985365 | No        |
| binlog.000002 |      2232 | No        |
| binlog.000003 |      2185 | No        |
+---------------+-----------+-----------+

# 트랜잭션 이벤트 확인
# SET @@SESSION.GTID_NEXT= 'bc720bb3-8df7-11f0-b1f3-f295eb9df264:1'
# => GTID로 구분되는 트랜잭션은 Gtid 이벤트 바로 다음에 나오는 Query 이벤트들
# => Gtid 이벤트가 '이 트랜잭션의 이름표(ID)는 이것입니다'라고 선언하면, 바로 뒤에 따라오는 Query 이벤트가 그 이름표를 가진 실제 작업 내용이 되는 구조
SHOW BINLOG EVENTS IN 'binlog.000003';
+---------------+------+----------------+-----------+-------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Log_name      | Pos  | Event_type     | Server_id | End_log_pos | Info                                                                                                                                                                             |
+---------------+------+----------------+-----------+-------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| binlog.000003 |    4 | Format_desc    |         1 |         127 | Server ver: 9.4.0, Binlog ver: 4                                                                                                                                                 |
| binlog.000003 |  127 | Previous_gtids |         1 |         158 |                                                                                                                                                                                  |
| binlog.000003 |  158 | Gtid           |         1 |         237 | SET @@SESSION.GTID_NEXT= 'bc720bb3-8df7-11f0-b1f3-f295eb9df264:1'                                                                                                                |
| binlog.000003 |  237 | Query          |         1 |         477 | ALTER USER 'root'@'localhost' IDENTIFIED WITH 'caching_sha2_password' AS '$A$005$jb!HJOuKFRy|/P<5PzeNSQN2iJFXfUD/i4WgO9aESBhfYaOKq1.f0kAdYD' /* xid=4 */                    |
| binlog.000003 |  477 | Gtid           |         1 |         554 | SET @@SESSION.GTID_NEXT= 'bc720bb3-8df7-11f0-b1f3-f295eb9df264:2'                                                                                                                |
| binlog.000003 |  554 | Query          |         1 |         712 | GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION /* xid=6 */                                                                                                          |
| binlog.000003 |  712 | Gtid           |         1 |         789 | SET @@SESSION.GTID_NEXT= 'bc720bb3-8df7-11f0-b1f3-f295eb9df264:3'                                                                                                                |
| binlog.000003 |  789 | Query          |         1 |         879 | FLUSH PRIVILEGES                                                                                                                                                                 |
| binlog.000003 |  879 | Gtid           |         1 |         958 | SET @@SESSION.GTID_NEXT= 'bc720bb3-8df7-11f0-b1f3-f295eb9df264:4'                                                                                                                |
| binlog.000003 |  958 | Query          |         1 |        1205 | CREATE USER IF NOT EXISTS 'root'@'10.244.12.%' IDENTIFIED WITH 'caching_sha2_password' AS '$A$005$\nEwREj4&8(%\\18c2zoXZzy9ECsCSlHNH0raeaA.j7N3aptkC6jQ3Xl6EA' /* xid=8 */ |
| binlog.000003 | 1205 | Gtid           |         1 |        1282 | SET @@SESSION.GTID_NEXT= 'bc720bb3-8df7-11f0-b1f3-f295eb9df264:5'                                                                                                                |
| binlog.000003 | 1282 | Query          |         1 |        1450 | GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.244.12.%' WITH GRANT OPTION /* xid=9 */                                                                                                |
| binlog.000003 | 1450 | Gtid           |         1 |        1529 | SET @@SESSION.GTID_NEXT= 'bc720bb3-8df7-11f0-b1f3-f295eb9df264:6'                                                                                                                |
| binlog.000003 | 1529 | Query          |         1 |        1774 | CREATE USER IF NOT EXISTS 'root'@'10.244.0.%' IDENTIFIED WITH 'caching_sha2_password' AS '$A$005$e:\'
| binlog.000003 | 1774 | Gtid           |         1 |        1851 | SET @@SESSION.GTID_NEXT= 'bc720bb3-8df7-11f0-b1f3-f295eb9df264:7'                                                                                                                |
| binlog.000003 | 1851 | Query          |         1 |        2018 | GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.244.0.%' WITH GRANT OPTION /* xid=11 */                                                                                                |
| binlog.000003 | 2018 | Gtid           |         1 |        2095 | SET @@SESSION.GTID_NEXT= 'bc720bb3-8df7-11f0-b1f3-f295eb9df264:8'                                                                                                                |
| binlog.000003 | 2095 | Query          |         1 |        2185 | FLUSH PRIVILEGES                                                                                                                                                                 |
+---------------+------+----------------+-----------+-------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
18 rows in set (0.001 sec)

############ [Active/Standby DB]
# exporter를 위해 'root'@'localhost'로 비밀번호 'root' 권한 부여
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
CREATE USER 'root'@'127.0.0.1' IDENTIFIED BY 'root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;

# 초기 사용자 PRIVILEGES 명시
CREATE USER 'root'@'%' IDENTIFIED BY '<NEW_PW>';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

# Access denied for user 'root'@'10.244.0.0' (using password: YES)
# 외부에서 접근시 Muti Worker Node들로의 CNI 접근 주소 허용용
CREATE USER IF NOT EXISTS 'root'@'10.244.12.%' IDENTIFIED BY '<NEW_PW>';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.244.12.%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'root'@'10.244.0.%' IDENTIFIED BY '<NEW_PW>';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.244.0.%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

