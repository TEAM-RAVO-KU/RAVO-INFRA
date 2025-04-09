sudo dnf update -y

### rkhunter Configuration
sudo dnf install -y epel-release
sudo dnf install -y rkhunter

sudo rkhunter --update

sudo crontab -e
: << "END"  
0 12 * * * /usr/bin/rkhunter --check --sk
END

### fail2ban Configuration
sudo yum install fail2ban -y

vim /etc/fail2ban/jail.conf
: << "END"  
[sshd]
enabled = true
maxretry = 10
findtime = 600
bantime = 86400
# ssh 포트를 열어두어서 호스트 머신이
# 차단하는 대상에게 sendmail하는 것에 너무 많은 리소스를 사용하는 것을 확인
# 따라서 [sshd] jail에 대해 sshd는 차단하되 메일은 보내지 않도록 설정
action = iptables[name=SSH, port=ssh, protocol=tcp]
END

sudo systemctl enable fail2ban --now
sudo systemctl status fail2ban

sudo fail2ban-client status sshd
