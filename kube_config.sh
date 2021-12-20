#!/usr/bin/env bash
echo "begin install kubectl."
export PATH="$PATH:/usr/local/bin"

server=$1
other_ips=$2

rm -rf ~/.kube
mkdir ~/.kube

echo "##########==> 上传工具"
cd /vagrant/tools
[ -d kubernetes ] || tar zxvf kubernetes-server-linux-amd64.tar.gz
\cp -rf kubernetes/server/bin/{kubectl,kube-controller-manager,kube-scheduler,kubelet,kube-proxy} /usr/local/bin
chmod +x /usr/local/bin/{kubectl,kube-controller-manager,kube-scheduler,kubelet,kube-proxy}

echo "##########==> 生成kubectl.kubeconfig配置文件"
cd /opt/cluster/ssl
kubectl config set-cluster kubernetes \
--certificate-authority=/opt/cluster/ssl/rootca/rootca.pem \
--embed-certs=true \
--server=https://${server}:6443 \
--kubeconfig=kubernetes/kubectl.kubeconfig

kubectl config set-credentials clusteradmin \
--client-certificate=/opt/cluster/ssl/kubernetes/kubectl.pem \
--client-key=/opt/cluster/ssl/kubernetes/kubectl-key.pem \
--embed-certs=true \
--kubeconfig=kubernetes/kubectl.kubeconfig

kubectl config set-context default \
--cluster=kubernetes \
--user=clusteradmin \
--kubeconfig=kubernetes/kubectl.kubeconfig

kubectl config use-context default \
--kubeconfig=kubernetes/kubectl.kubeconfig

\cp -rf /opt/cluster/ssl/kubernetes/kubectl.kubeconfig ~/.kube/config
[ -d /home/vagrant/.kube ] || mkdir -p /home/vagrant/.kube
\cp -rf /opt/cluster/ssl/kubernetes/kubectl.kubeconfig /home/vagrant/.kube/config
chmod 755 /home/vagrant/.kube/config

echo "##########==> 编写kube-controller-manager.kubeconfig配置文件"
kubectl config set-cluster kubernetes --certificate-authority=/opt/cluster/ssl/rootca/rootca.pem \
  --embed-certs=true --server=https://${server}:6443 \
  --kubeconfig=kubernetes/kube-controller-manager.kubeconfig

kubectl config set-credentials kube-controller-manager --client-certificate=kubernetes/kube-controller-manager.pem \
  --client-key=kubernetes/kube-controller-manager-key.pem --embed-certs=true \
  --kubeconfig=kubernetes/kube-controller-manager.kubeconfig

kubectl config set-context default --cluster=kubernetes --user=kube-controller-manager \
  --kubeconfig=kubernetes/kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kubernetes/kube-controller-manager.kubeconfig


echo "##########==> 编写kube-scheduler.kubeconfig配置文件"
kubectl config set-cluster kubernetes --certificate-authority=/opt/cluster/ssl/rootca/rootca.pem \
  --embed-certs=true --server=https://${server}:6443 \
  --kubeconfig=kubernetes/kube-scheduler.kubeconfig

kubectl config set-credentials kube-scheduler --client-certificate=kubernetes/kube-scheduler.pem \
  --client-key=kubernetes/kube-scheduler-key.pem --embed-certs=true \
  --kubeconfig=kubernetes/kube-scheduler.kubeconfig

kubectl config set-context default --cluster=kubernetes --user=kube-scheduler \
  --kubeconfig=kubernetes/kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kubernetes/kube-scheduler.kubeconfig


echo "##########==> 编写kubelet.conf配置文件"
kubectl config set-cluster kubernetes --certificate-authority=/opt/cluster/ssl/rootca/rootca.pem \
  --embed-certs=true --server=https://${server}:6443 \
  --kubeconfig=kubernetes/kubelet-bootstrap.kubeconfig

kubectl config set-credentials kubelet-bootstrap --token=$(awk -F "," '{print $1}' /opt/cluster/ssl/kubernetes/kube-apiserver.token.csv) \
  --kubeconfig=kubernetes/kubelet-bootstrap.kubeconfig

kubectl config set-context default --cluster=kubernetes --user=kubelet-bootstrap \
  --kubeconfig=kubernetes/kubelet-bootstrap.kubeconfig

#此处不知为啥会创建失败
# failed to create clusterrolebinding: Post "https://192.168.56.100:6443/apis/rbac.authorization.k8s.io/v1/clusterrolebindings?fieldManager=kubectl-create": read tcp 192.168.56.100:51964->192.168.56.100:6443: read: connection reset by peer
kubectl config use-context default --kubeconfig=kubernetes/kubelet-bootstrap.kubeconfig

cat > kubernetes/kubelet.conf <<EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 0.0.0.0
port: 10250
readOnlyPort: 0
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 2m0s
    enabled: true
  x509:
    clientCAFile: /opt/cluster/ssl/rootca/rootca.pem
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s
cgroupDriver: systemd
clusterDNS:
- 10.96.0.10
clusterDomain: cluster.local
healthzBindAddress: 127.0.0.1
healthzPort: 10248
rotateCertificates: true
evictionHard:
  imagefs.available: 15%
  memory.available: 100Mi
  nodefs.available: 10%
  nodefs.inodesFree: 5%
maxOpenFiles: 1000000
maxPods: 110
EOF


echo "##########==> 编写kube-proxy.kubeconfig文件"
kubectl config set-cluster kubernetes --certificate-authority=/opt/cluster/ssl/rootca/rootca.pem \
  --embed-certs=true --server=https://${server}:6443 \
  --kubeconfig=kubernetes/kube-proxy.kubeconfig

kubectl config set-credentials kube-proxy --client-certificate=/opt/cluster/ssl/kubernetes/kube-proxy.pem \
  --client-key=/opt/cluster/ssl/kubernetes/kube-proxy-key.pem --embed-certs=true \
  --kubeconfig=kubernetes/kube-proxy.kubeconfig

kubectl config set-context default --cluster=kubernetes --user=kube-proxy \
  --kubeconfig=kubernetes/kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kubernetes/kube-proxy.kubeconfig


echo "##########==> 编写kube-proxy配置文件"
cat > kubernetes/kube-proxy.conf <<EOF
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: /opt/cluster/ssl/kubernetes/kube-proxy.kubeconfig
bindAddress: 0.0.0.0
clusterCIDR: "10.97.0.0/16"
healthzBindAddress: "0.0.0.0:10256"
metricsBindAddress: "0.0.0.0:10249"
mode: ipvs
ipvs:
  scheduler: "rr"
EOF

echo "##########==> 传递证书到其他node"
echo $other_ips | xargs -n1 | while read ip
do 
  echo "scp -> $ip"
  scp -r  -o StrictHostKeyChecking=no /opt/cluster/ssl ${ip}:/opt/cluster
done
