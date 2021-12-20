#!/usr/bin/env bash

echo "begin install kube-api."
export PATH="$PATH:/usr/local/bin"

local_ip=`ifconfig eth1 | grep "broadcast" | awk -F" " '{print $2}'`
etcd_servers=$1

#如果要重新部署一定要清理残留数据
rm -rf /usr/local/bin/kube-apiserver
rm -rf /usr/lib/systemd/system/kube-apiserver.service
rm -rf /opt/cluster/log/kube-apiserver

mkdir -p /opt/cluster/log/kube-apiserver
\cp -rf /vagrant/ssl  /opt/cluster

echo "##########==> 上传工具"
cd /vagrant/tools
[ -d kubernetes ] || tar zxvf kubernetes-server-linux-amd64.tar.gz
\cp -rf kubernetes/server/bin/kube-apiserver /usr/local/bin
chmod +x /usr/local/bin/kube-apiserver


echo "##########==> 生成token.csv"
cd /opt/cluster/ssl
echo $(head -c 16 /dev/urandom | od -An -t x | tr -d ' '),kubelet-bootstrap,10001,"system:kubelet-bootstrap" > kubernetes/kube-apiserver.token.csv

cat > /usr/lib/systemd/system/kube-apiserver.service <<EOF
[Unit]
Description=Kubernetes:Apiserver
After=network.target network-online.target
Wants=network-online.target

[Service]
Restart=on-failure
RestartSec=5
ExecStart=/usr/local/bin/kube-apiserver \
--runtime-config=api/all=true \
--anonymous-auth=false \
--bind-address=0.0.0.0 \
--advertise-address=${local_ip} \
--secure-port=6443 \
--tls-cert-file=/opt/cluster/ssl/kubernetes/kube-apiserver.pem \
--tls-private-key-file=/opt/cluster/ssl/kubernetes/kube-apiserver-key.pem \
--client-ca-file=/opt/cluster/ssl/rootca/rootca.pem \
--etcd-cafile=/opt/cluster/ssl/rootca/rootca.pem \
--etcd-certfile=/opt/cluster/ssl/etcd/etcd.pem \
--etcd-keyfile=/opt/cluster/ssl/etcd/etcd-key.pem \
--etcd-servers=${etcd_servers} \
--kubelet-client-certificate=/opt/cluster/ssl/kubernetes/kube-apiserver.pem \
--kubelet-client-key=/opt/cluster/ssl/kubernetes/kube-apiserver-key.pem \
--service-account-key-file=/opt/cluster/ssl/rootca/rootca-key.pem \
--service-account-signing-key-file=/opt/cluster/ssl/rootca/rootca-key.pem \
--service-account-issuer=https://kubernetes.default.svc.cluster.local \
--enable-bootstrap-token-auth=true \
--token-auth-file=/opt/cluster/ssl/kubernetes/kube-apiserver.token.csv \
--allow-privileged=true \
--service-cluster-ip-range=10.96.0.0/16 \
--service-node-port-range=30000-50000 \
--authorization-mode=RBAC,Node \
--enable-aggregator-routing=true \
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,NodeRestriction \
--audit-log-maxage=30 \
--audit-log-maxbackup=3 \
--audit-log-maxsize=100 \
--audit-log-path=/opt/cluster/log/kube-apiserver/audit.log \
--logtostderr=false \
--v=2 \
--log-dir=/opt/cluster/log/kube-apiserver

[Install]
WantedBy=multi-user.target
EOF

echo "##########==> 启动kube-apiserver"
systemctl daemon-reload
systemctl enable --now kube-apiserver.service
systemctl status kube-apiserver.service