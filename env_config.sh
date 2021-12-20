#!/usr/bin/env bash

echo "begin install_common.sh"
export PATH="$PATH:/usr/local/bin"

cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timedatectl set-timezone Asia/Shanghai

echo 'set nameserver'
echo "nameserver 8.8.8.8">/etc/resolv.conf
cat /etc/resolv.conf

echo "update yum.repos.d"
mkdir -p /etc/yum.repos.d/repo_bak
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/repo_bak/
curl -s -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
dnf clean all
dnf makecache
dnf repolist

# 安装常用软件
dnf -y install epel-release 
dnf -y install wget 
dnf -y install conntrack-tools 
dnf -y install vim 
dnf -y install net-tools 
dnf -y install telnet 
dnf -y install tcpdump 
dnf -y install bind-utils 
dnf -y install socat 
dnf -y install chrony 
dnf -y install kmod 
dnf -y install dos2unix 
yum install ipvsadm ipset sysstat conntrack libseccomp -y


#关闭防火墙、selinux、swap
echo 'disable firewalld、selinux、swap'
systemctl stop firewalld
systemctl disable firewalld
sed -i 's/enforcing/disabled/' /etc/selinux/config 
setenforce 0
swapoff -a  
sed -ri 's/.*swap.*/#&/' /etc/fstab

# 同步服务器时间
echo 'sync time'
systemctl enable chronyd 
systemctl start chronyd 
chronyc sources


#配置网络转发及系统优化
echo 'enable iptable kernel parameter'
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward=1
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF

#加载配置生效
modprobe br_netfilter 
sysctl -p /etc/sysctl.d/k8s.conf 

echo 'set host name resolution'
echo -e $@ | xargs -n1 -n2 >> /etc/hosts
cat /etc/hosts


#确保每台机器的uuid不一致，如果是克隆机器，修改网卡配置文件删除uuid那一行
cat /sys/class/dmi/id/product_uuid


cat /vagrant/.ssh/authorized_keys > ~/.ssh/authorized_keys
sed -i "/$HOSTNAME/d" ~/.ssh/authorized_keys

chmod +x  /usr/local/bin/

