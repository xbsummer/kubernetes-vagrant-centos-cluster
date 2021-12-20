#!/usr/bin/env bash

echo "begin install etcd."
export PATH="$PATH:/usr/local/bin"

etcd_version=`grep "etcd_version" /vagrant/config.yaml | cut -d" " -f2 | sed "s/\n//g"`
local_ip=`ifconfig eth1 | grep "broadcast" | awk -F" " '{print $2}'`
echo "入参: $@"
etcd_name=$1
etcd_cluster=$2

#如果要重新部署一定要清理残留数据
rm -rf /opt/cluster/etcd
rm -rf /usr/lib/systemd/system/etcd.service
rm -rf /usr/local/bin/{etcd,etcdctl}

mkdir -p /opt/cluster/etcd/{data,wal}

echo "##########==> 处理etcd工具"
cd /vagrant/tools
[ -d etcd-${etcd_version}-linux-amd64 ] || tar zxvf etcd-${etcd_version}-linux-amd64.tar.gz
\cp -rf etcd-${etcd_version}-linux-amd64/{etcd,etcdctl} /usr/local/bin
chmod +x /usr/local/bin/{etcd,etcdctl}

echo "##########==> 部署etcd"
cat > /usr/lib/systemd/system/etcd.service <<EOF
[Unit]
Description=Kubernetes:Etcd
After=network.target network-online.target
Wants=network-online.target

[Service]
Restart=on-failure
RestartSec=5
ExecStart=/usr/local/bin/etcd \
--name=${etcd_name} \
--data-dir=/opt/cluster/etcd/data \
--wal-dir=/opt/cluster/etcd/wal \
--listen-peer-urls=https://${local_ip}:2380 \
--listen-client-urls=https://${local_ip}:2379,http://127.0.0.1:2379 \
--initial-advertise-peer-urls=https://${local_ip}:2380 \
--initial-cluster=${etcd_cluster} \
--initial-cluster-state=new \
--initial-cluster-token=373b3543a301630c \
--advertise-client-urls=https://${local_ip}:2379 \
--cert-file=/opt/cluster/ssl/etcd/etcd.pem \
--key-file=/opt/cluster/ssl/etcd/etcd-key.pem \
--peer-cert-file=/opt/cluster/ssl/etcd/etcd.pem \
--peer-key-file=/opt/cluster/ssl/etcd/etcd-key.pem \
--trusted-ca-file=/opt/cluster/ssl/rootca/rootca.pem \
--peer-trusted-ca-file=/opt/cluster/ssl/rootca/rootca.pem \
--client-cert-auth=true \
--peer-client-cert-auth=true \
--logger=zap \
--log-outputs=default \
--log-level=info \
--listen-metrics-urls=https://${local_ip}:2381 \
--enable-pprof=false

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable etcd.service
systemctl start etcd.service
systemctl status etcd.service 


#查看错误信息
#journalctl -u etcd

# 只有etcd集群起好了才能验证， 不然会报错。
# echo "##########==> 验证etcd"
# etcdctl \
# --cacert=/opt/cluster/ssl/rootca/rootca.pem \
# --cert=/opt/cluster/ssl/etcd/etcd.pem \
# --key=/opt/cluster/ssl/etcd/etcd-key.pem \
# --endpoints="https://192.168.56.100:2379,https://192.168.56.101:2379,https://192.168.56.102:2379" \
# endpoint health --write-out=table
