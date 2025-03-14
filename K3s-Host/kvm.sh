### libvirt 디렉터리 생성
mkdir -p /home/libvirt/images
cd /home/libvirt/images

### Rocky Linux 이미지 wget
dnf install -y wget
wget https://dl.rockylinux.org/vault/rocky/9.2/isos/x86_64/Rocky-9.2-x86_64-minimal.iso
ls
# Rocky-9.2-x86_64-minimal.iso

### KVM 관련 패키지 설치
dnf -y install qemu-kvm libvirt libvirt-daemon libvirt-client virt-install virt-viewer virt-manager
sudo systemctl enable libvirtd --now


### 호스트 정보 확인
df -h
free -h
grep -c processor /proc/cpuinfo

### libvirt network 정의
virsh net-define ./k3snat.xml
virsh net-autostart k3snat
virsh net-start k3snat

### k3s-libvirt 이미지 생성
virt-install \
  --name k3s \
  --ram 6144 \
  --vcpus 3 \
  --disk path=/home/libvirt/images/k3s.qcow2,size=100 \
  --os-variant rocky9.0 \
  --location /home/libvirt/images/Rocky-9.2-x86_64-minimal.iso \
  --extra-args "inst.text console=ttyS0,115200n8" \
  --network network=k3snat,model=virtio \
  --graphics none

### 호스트의 터미널 사이즈와 통일
### k3s-kvm
echo "export TERM=xterm-256color" >> ~/.bashrc
source ~/.bashrc
