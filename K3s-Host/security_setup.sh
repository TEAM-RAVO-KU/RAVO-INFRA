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
END

sudo systemctl enable fail2ban --now
sudo systemctl status fail2ban

sudo fail2ban-client status sshd
