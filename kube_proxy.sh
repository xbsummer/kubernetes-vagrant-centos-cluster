#!/usr/bin/env bash
echo "begin install kube-proxy."
export PATH="$PATH:/usr/local/bin"

rm -rf /usr/lib/systemd/system/kube-proxy.service
rm -rf /opt/cluster/log/kube-proxy

mkdir -p /opt/cluster/log/kube-proxy

echo "##########==> 上传工具"
cd /vagrant/tools
[ -d kubernetes ] || tar zxvf kubernetes-server-linux-amd64.tar.gz
\cp -rf kubernetes/server/bin/kube-proxy /usr/local/bin
chmod +x /usr/local/bin/kube-proxy

echo "##########==> 编写systemd配置文件..."
cat > /usr/lib/systemd/system/kube-proxy.service <<EOF
[Unit]
Description=Kubernetes:Kube-Proxy
After=network.target network-online.target
Wants=network-online.target

[Service]
Restart=on-failure
RestartSec=5
ExecStart=/usr/local/bin/kube-proxy \
  --config=/opt/cluster/ssl/kubernetes/kube-proxy.conf \
  --logtostderr=false \
  --v=2 \
  --log-dir=/opt/cluster/log/kube-proxy \
  --hostname-override=$hostname
                  
[Install]
WantedBy=multi-user.target
EOF

echo "##########==> 启动kube-proxy"
systemctl daemon-reload && \
systemctl enable --now kube-proxy.service && \
systemctl status kube-proxy.service