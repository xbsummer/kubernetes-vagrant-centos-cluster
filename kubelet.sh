#!/usr/bin/env bash
echo "begin install kubelet."
export PATH="$PATH:/usr/local/bin"

rm -rf /opt/cluster/log/kubelet
rm -rf /opt/cluster/kubelet/ssl
rm -rf /usr/local/bin/kubelet

mkdir -p /opt/cluster/log/kubelet
mkdir -p /opt/cluster/kubelet/ssl

echo "##########==> 上传工具"
cd /vagrant/tools
[ -d kubernetes ] || tar zxvf kubernetes-server-linux-amd64.tar.gz
\cp -rf kubernetes/server/bin/kubelet /usr/local/bin
chmod +x /usr/local/bin/kubelet

echo "编写systemd配置文件..."
cat > /usr/lib/systemd/system/kubelet.service << "EOF"
[Unit]
Description=Kubernetes:Kubelet
After=network.target network-online.target docker.service
Requires=docker.service

[Service]
Restart=on-failure
RestartSec=5
ExecStart=/usr/local/bin/kubelet \
  --bootstrap-kubeconfig=/opt/cluster/ssl/kubernetes/kubelet-bootstrap.kubeconfig \
  --config=/opt/cluster/ssl/kubernetes/kubelet.conf \
  --kubeconfig=/opt/cluster/kubelet/kubelet.kubeconfig \
  --cert-dir=/opt/cluster/kubelet/ssl \
  --network-plugin=cni \
  --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 \
  --logtostderr=false \
  --v=2 \
  --log-dir=/opt/cluster/log/kubelet
                  
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload && \
systemctl enable --now kubelet.service && \
systemctl status kubelet.service


