### Firewalld configuration
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --permanent --zone=public --add-port=3307/tcp
sudo firewall-cmd --reload

firewall-cmd --list-ports
# 3306/tcp 3307/tcp

### Deploy container in background mode
docker-compose up -d

docker ps
: << "END"  
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS         PORTS
                                         NAMES
40cc5fbc1f58   mysql:latest   "docker-entrypoint.s…"   5 seconds ago   Up 3 seconds   0.0.0.0:3306->3306/tcp, [::]:3306->3306/tcp, 33060/tcp   mysql-live
64d4cc5347fc   mysql:latest   "docker-entrypoint.s…"   5 seconds ago   Up 3 seconds   33060/tcp, 0.0.0.0:3307->3306/tcp, [::]:3307->3306/tcp   mysql-standby
END

### mysql-live container test
docker-compose exec mysql-live bash

mysql -u root -p
# password: root
: << "END"  
mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| live_db            |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.02 sec)
END

### mysql-live container test
docker-compose exec mysql-standby bash

mysql -u root -p
# password: root
: << "END"  
mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| live_db            |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.02 sec)
END

### Data Store Locations
ls -al
: << "END"  
total 16
-rw-r--r--. 1 root             root  808 Mar 18 02:18 docker-compose.yaml
drwxr-xr-x. 8 systemd-coredump root 4096 Mar 18 02:20 mysql-live-data
drwxr-xr-x. 8 systemd-coredump root 4096 Mar 18 02:20 mysql-standby-data
END
