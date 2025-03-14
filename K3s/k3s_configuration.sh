sudo dnf update -y
sudo dnf install -y curl vim

### SELinux Disable
setenforce 0
vim /etc/selinux/config
# SELINUX=disabled
getenforce

### firewalld 중지
systemctl stop firewalld
systemctl disable firewalld

### K3s 설치
curl -sfL https://get.k3s.io | sh -

### Kubeconfig 파일 사용
# K3s는 기본적으로 /etc/rancher/k3s/k3s.yaml에 kubeconfig 파일을 생성
# 이를 사용자의 kubeconfig 위치(~/.kube/config)로 복사하여 관리할 수 있음
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

### K3s 상태 확인
systemctl status k3s
kubectl get nodes

### kubectl alias 설정
echo 'alias k="kubectl"' >> ~/.bashrc
source ~/.bashrc

k get nodes
# NAME   STATUS   ROLES                  AGE    VERSION
# k3s    Ready    control-plane,master   117s   v1.31.6+k3s1
