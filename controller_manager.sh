#!/usr/bin/env bash
echo "begin install controller_manager."
export PATH="$PATH:/usr/local/bin"

rm -rf /usr/lib/systemd/system/kube-controller-manager.service
rm -rf /opt/cluster/log/kube-controller-manager

mkdir -p /opt/cluster/log/kube-controller-manager

echo "##########==> 上传工具"
cd /vagrant/tools
[ -d kubernetes ] || tar zxvf kubernetes-server-linux-amd64.tar.gz
\cp -rf kubernetes/server/bin/kube-controller-manager /usr/local/bin
chmod +x /usr/local/bin/kube-controller-manager

echo "##########==> 编写systemd配置文件"
cat > /usr/lib/systemd/system/kube-controller-manager.service <<EOF
[Unit]
Description=Kubernetes:Kube-Controller-Manager
After=network.target network-online.target
Wants=network-online.target

[Service]
Restart=on-failure
RestartSec=5
ExecStart=/usr/local/bin/kube-controller-manager \
  --cluster-name=kubernetes \
  --secure-port=10257 \
  --bind-address=127.0.0.1 \
  --service-cluster-ip-range=10.96.0.0/16 \
  --allocate-node-cidrs=true \
  --cluster-cidr=10.97.0.0/16 \
  --leader-elect=true \
  --controllers=*,bootstrapsigner,tokencleaner \
  --kubeconfig=/opt/cluster/ssl/kubernetes/kube-controller-manager.kubeconfig \
  --tls-cert-file=/opt/cluster/ssl/kubernetes/kube-controller-manager.pem \
  --tls-private-key-file=/opt/cluster/ssl/kubernetes/kube-controller-manager-key.pem \
  --cluster-signing-cert-file=/opt/cluster/ssl/rootca/rootca.pem \
  --cluster-signing-key-file=/opt/cluster/ssl/rootca/rootca-key.pem \
  --cluster-signing-duration=87600h0m0s \
  --use-service-account-credentials=true \
  --root-ca-file=/opt/cluster/ssl/rootca/rootca.pem \
  --service-account-private-key-file=/opt/cluster/ssl/rootca/rootca-key.pem \
  --logtostderr=false \
  --v=2 \
  --log-dir=/opt/cluster/log/kube-controller-manager

[Install]
WantedBy=multi-user.target
EOF

echo "##########==> 启动kube-controller-manager"
systemctl daemon-reload && \
systemctl enable --now kube-controller-manager.service && \
systemctl status kube-controller-manager.service