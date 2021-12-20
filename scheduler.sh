#!/usr/bin/env bash
echo "begin install scheduler."
export PATH="$PATH:/usr/local/bin"

rm -rf /usr/lib/systemd/system/kube-scheduler.service
rm -rf /opt/cluster/log/kube-scheduler
mkdir -p /opt/cluster/log/kube-scheduler

echo "##########==> 上传工具"
cd /vagrant/tools
[ -d kubernetes ] || tar zxvf kubernetes-server-linux-amd64.tar.gz
\cp -rf kubernetes/server/bin/kube-scheduler /usr/local/bin
chmod +x /usr/local/bin/kube-scheduler

echo "##########==> 编写kube-scheduler systemd配置文件"
cat > /usr/lib/systemd/system/kube-scheduler.service <<EOF
[Unit]
Description=Kubernetes:Kube-Scheduler
After=network.target network-online.target
Wants=network-online.target

[Service]
Restart=on-failure
RestartSec=5
ExecStart=/usr/local/bin/kube-scheduler \
  --kubeconfig=/opt/cluster/ssl/kubernetes/kube-scheduler.kubeconfig \
  --address=127.0.0.1 \
  --leader-elect=true \
  --logtostderr=false \
  --v=2 \
  --log-dir=/opt/cluster/log/kube-scheduler

[Install]
WantedBy=multi-user.target
EOF

echo "##########==> 启动kube-scheduler"
systemctl daemon-reload && \
systemctl enable --now kube-scheduler.service && \
systemctl status kube-scheduler.service