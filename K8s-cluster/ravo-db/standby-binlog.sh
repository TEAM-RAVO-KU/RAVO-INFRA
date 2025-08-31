kubectl create configmap mysql-standby-binlog-config --from-literal=98-binlog.cnf='
[mysqld]
# Active와 다른 고유 ID 설정
server-id = 223345
# binlog 파일명 접두어 지정 및 활성화
log_bin   = mysql-bin-standby
'

kubectl patch deployment mysql-standby --type='json' -p='[
  {"op": "add", "path": "/spec/template/spec/volumes/-", "value": {
    "name": "mysql-standby-binlog",
    "configMap": {
      "name": "mysql-standby-binlog-config"
    }
  }},
  {"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts/-", "value": {
    "name": "mysql-standby-binlog",
    "mountPath": "/etc/mysql/conf.d"
  }}
]'

kubectl exec -it pod/mysql-standby-XXXX -- bash
# ConfigMap 적용 확인
ls -l /etc/mysql/conf.d/98-binlog.cnf
cat /etc/mysql/conf.d/98-binlog.cnf

# 설정 확인
<< 'END'
mysql> SHOW VARIABLES LIKE 'log_bin';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| log_bin       | ON    |
+---------------+-------+
1 row in set (0.113 sec)

mysql> SHOW VARIABLES LIKE 'binlog_format';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| binlog_format | ROW   |
+---------------+-------+
1 row in set (0.010 sec)

mysql> SHOW VARIABLES LIKE 'server_id';
+---------------+--------+
| Variable_name | Value  |
+---------------+--------+
| server_id     | 223345 |
+---------------+--------+
1 row in set (0.012 sec)

mysql> SHOW BINARY LOGS;
+--------------------------+-----------+-----------+
| Log_name                 | File_size | Encrypted |
+--------------------------+-----------+-----------+
| mysql-bin-standby.000001 |       158 | No        |
+--------------------------+-----------+-----------+
1 row in set (0.001 sec)
END

SELECT user, host FROM mysql.user WHERE user = 'root';
ALTER USER 'root'@'localhost' IDENTIFIED BY '<NEW_PW>';
CREATE USER 'root'@'%' IDENTIFIED BY '<NEW_PW>';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

CREATE USER IF NOT EXISTS 'root'@'10.244.12.%' IDENTIFIED BY '<NEW_PW>';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.244.12.%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'root'@'10.244.0.%' IDENTIFIED BY '<NEW_PW>';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.244.0.%' WITH GRANT OPTION;
FLUSH PRIVILEGES;