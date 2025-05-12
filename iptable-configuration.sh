sudo yum install -y iptables-services
sudo systemctl enable iptables
sudo systemctl enable ip6tables

sudo iptables-save | sudo tee /etc/sysconfig/iptables
sudo ip6tables-save | sudo tee /etc/sysconfig/ip6tables

sudo systemctl restart iptables
sudo iptables -t nat -L -n --line-numbers

### [kafka-broker 관련 설정]
# 이후 수동으로 iptables를 규칙을 정의하여 enp2s0와 lo에 대해
# 이후 메타데이터(30092) 연결에 대해서는 9095→30092로 점프할 수 있도록 허용
# 외부에서 들어오는 패킷(PREROUTING)에 대한 규칙
sudo iptables -t nat -I PREROUTING \
	-i enp2s0 -p tcp --dport 30092 \
	-j REDIRECT --to-ports 9095

# 같은 호스트(OUTPUT)에서 30092로 접속할 때의 규칙
sudo iptables -t nat -I OUTPUT \
  -o lo -p tcp -d <호스트 Public IP> --dport 30092 \
  -j REDIRECT --to-ports 9095