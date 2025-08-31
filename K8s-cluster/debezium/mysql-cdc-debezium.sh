kubectl apply -f mysql-cdc-configmap.yaml

# mysql-active Deployment mysql-cdc-config patch
kubectl -n default patch deploy mysql-active \
  --type=json \
  -p='[
    {"op":"add","path":"/spec/template/spec/volumes/-",
     "value":{"name":"mysql-cdc","configMap":{"name":"mysql-cdc-config"}}},
    {"op":"add","path":"/spec/template/spec/containers/0/volumeMounts/-",
     "value":{"name":"mysql-cdc","mountPath":"/etc/mysql/conf.d/99-debezium.cnf","subPath":"99-debezium.cnf"}}
  ]'

kubectl rollout restart deployment mysql-active

kubectl exec -it pod/mysql-active-XXXX -- bash
# ConfigMap 적용 확인
ls -l /etc/mysql/conf.d/99-debezium.cnf
cat /etc/mysql/conf.d/99-debezium.cnf

# Debezium 전용 계정 생성
mysql -u root -p
<< 'END'
CREATE USER IF NOT EXISTS 'debezium'@'%' IDENTIFIED BY 'dbz!pass';
GRANT REPLICATION SLAVE, REPLICATION CLIENT, SELECT, RELOAD, SHOW DATABASES ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;
END

# 설정 확인
<< 'END'
SHOW VARIABLES LIKE 'log_bin';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| log_bin       | ON    |
+---------------+-------+
1 row in set (0.010 sec)

SHOW VARIABLES LIKE 'binlog_format';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| binlog_format | ROW   |
+---------------+-------+
1 row in set (0.017 sec)

SHOW VARIABLES LIKE 'server_id';
+---------------+--------+
| Variable_name | Value  |
+---------------+--------+
| server_id     | 223344 |
+---------------+--------+
1 row in set (0.009 sec)

SHOW BINARY LOGS;
+------------------+-----------+-----------+
| Log_name         | File_size | Encrypted |
+------------------+-----------+-----------+
| mysql-bin.000006 |       158 | No        |
| mysql-bin.000007 |       923 | No        |
+------------------+-----------+-----------+
2 rows in set (0.002 sec)
END

ALTER USER 'root'@'localhost' IDENTIFIED BY '<NEW_PW>';
CREATE USER 'root'@'%' IDENTIFIED BY '<NEW_PW>';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

CREATE USER IF NOT EXISTS 'root'@'10.244.12.%' IDENTIFIED BY '<NEW_PW>';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.244.12.%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'root'@'10.244.0.%' IDENTIFIED BY '<NEW_PW>';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.244.0.%' WITH GRANT OPTION;
FLUSH PRIVILEGES;