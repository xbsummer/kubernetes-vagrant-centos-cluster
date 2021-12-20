#!/usr/bin/env bash
echo "begin install coredns."
export PATH="$PATH:/usr/local/bin"

rm -rf /opt/cluster/plugins/coredns
mkdir -p /opt/cluster/plugins/coredns

echo "##########==> 上传工具"
cd /opt/cluster/plugins/coredns
\cp -rf /vagrant/tools/coredns.yaml ./


echo "##########==> 启动coredns"
kubectl delete -f coredns.yaml --ignore-not-found=true
kubectl apply -f coredns.yaml