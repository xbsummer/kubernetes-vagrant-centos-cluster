#!/usr/bin/env bash
echo "begin install calico."
export PATH="$PATH:/usr/local/bin"

rm -rf /opt/cluster/plugins/calico
rm -rf /opt/cni/bin/calico
rm -rf /run/calico
rm -rf /sys/fs/bpf/calico
rm -rf /var/log/calico
rm -rf /var/lib/calico
mkdir -p /opt/cluster/plugins/calico

echo "##########==> 上传工具"
cd /opt/cluster/plugins/calico
\cp -rf /vagrant/tools/calico.yaml ./
chmod +x ./calico.yaml

#开启CALICO_IPV4POOL_CIDR并修改value
sed -i 's/#.*CALICO_IPV4POOL_CIDR/- name: CALICO_IPV4POOL_CIDR/g' calico.yaml
sed -i '/CALICO_IPV4POOL_CIDR/{N;s/#.*$/  value: "10.97.0.0\/16"/g}' calico.yaml

echo "##########==> calico"
kubectl delete -f calico.yaml --ignore-not-found=true
kubectl apply -f calico.yaml

#当无法启动calico插件时，需要先使用docker pull拉取它们以排查是否是网络原因造成的无法启动
#grep image calico.yml | awk -F": " '{print $2}' | while read image; do docker pull $image; done