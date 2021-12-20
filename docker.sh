#!/usr/bin/env bash

echo "begin install docker."
export PATH="$PATH:/usr/local/bin"

rm -rf /usr/lib/systemd/system/docker.service
rm -rf /usr/bin/docker
rm -rf /etc/docker

mkdir /etc/docker

docker_version=`grep "docker_version" /vagrant/config.yaml | cut -d" " -f2 | sed "s/\n//g"` 

echo "##########==> 处理docker工具"
cd /vagrant/tools
[ -d docker ] || tar zxvf docker-${docker_version}.tgz
\cp -rf docker/* /usr/bin

echo "##########==> 安装docker"
cat > /usr/lib/systemd/system/docker.service <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target
[Service]
Type=notify
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s
[Install]
WantedBy=multi-user.target
EOF


#参考https://www.cnblogs.com/hongdada/p/9771857.html  native.cgroupdriver=systemd的原因
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": [
    "native.cgroupdriver=systemd"
  ],
  "log-driver": "json-file",
  "log-level": "warn",
  "log-opts": {
    "max-size": "1000m",
    "max-file": "3"
  },
  "registry-mirrors": [
    "https://reg-mirror.qiniu.com",
    "https://hub-mirror.c.163.com",
    "https://mirror.ccs.tencentyun.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://dockerhub.azk8s.cn",
    "https://registry.docker-cn.com"
  ],
  "insecure-registries": [],
  "selinux-enabled": false
}
EOF

echo "##########==> 创建docker group"
#create group if not exists
egrep "^docker" /etc/group >& /dev/null
if [ $? -ne 0 ]
then
  groupadd docker
fi

usermod -aG docker vagrant

echo "##########==> 启动docker"
systemctl daemon-reload
systemctl start docker
systemctl enable docker
systemctl status docker