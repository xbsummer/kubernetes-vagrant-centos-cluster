#!/usr/bin/env bash

echo "begin install cfssl."
export PATH="$PATH:/usr/local/bin"

etcd_ips=$1
apiserver_hosts=$2
other_ips=$3

# 先清理文件夹
rm -rf /opt/cluster/ssl/
rm -rf /usr/local/bin/cfssl*

mkdir -p /opt/cluster/ssl/{rootca,etcd,kubernetes}

echo "##########==> 处理cfssl工具"
cd /opt/cluster/ssl
cfssl_version=`grep "cfssl_version" /vagrant/config.yaml | cut -d" " -f2 | sed "s/\n//g"` 

\cp -rf /vagrant/tools/cfssl_${cfssl_version:1}_linux_amd64 /usr/local/bin/cfssl
\cp -rf /vagrant/tools/cfssl-certinfo_${cfssl_version:1}_linux_amd64  /usr/local/bin/cfssl-certinfo
\cp -rf /vagrant/tools/cfssljson_${cfssl_version:1}_linux_amd64 /usr/local/bin/cfssljson
chmod +x /usr/local/bin/cfssl*

echo "##########==> 生成根证书"
cat > cfssl-conf.json <<EOF
{
  "signing": {
    "default": {"expiry": "87600h"},
    "profiles": {
      "common": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "87600h"
      }
    }
  }
}
EOF
cat > rootca/rootca-csr.json <<EOF
{
  "CN": "rootca",
  "key": {"algo": "ecdsa", "size": 256},
  "names": [{"C": "CN", "ST": "ChongQing", "L": "ChongQing", "O": "ROOTCA", "OU": "tz"}]
}
EOF
cfssl gencert -initca rootca/rootca-csr.json | cfssljson -bare rootca/rootca

echo "##########==> 生成etcd证书"
cat > etcd/etcd-csr.json <<EOF
{
  "CN": "etcd-cluster",
  "hosts": ["127.0.0.1", ${etcd_ips}],
  "key": {"algo": "ecdsa", "size": 256},
  "names": [{"C": "CN", "ST": "ChongQing", "L": "ChongQing", "O": "KUBERNETES-ETCD", "OU": "tz"}]
}
EOF
cfssl gencert -ca=rootca/rootca.pem -ca-key=rootca/rootca-key.pem --config=cfssl-conf.json -profile=common etcd/etcd-csr.json | cfssljson -bare etcd/etcd

echo "##########==> 生成kube-apiserver证书"
cat > kubernetes/kube-apiserver-csr.json <<EOF
{
  "CN": "kube-apiserver",
  "hosts": [
    "127.0.0.1", ${apiserver_hosts}, "10.96.0.1",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
  "key": {"algo": "ecdsa", "size": 256},
  "names": [{"C": "CN", "L": "ChongQing", "ST": "ChongQing", "O": "system:masters", "OU": "tz"}]
}
EOF

cfssl gencert \
-ca=rootca/rootca.pem \
-ca-key=rootca/rootca-key.pem \
--config=cfssl-conf.json \
-profile=common kubernetes/kube-apiserver-csr.json | cfssljson -bare kubernetes/kube-apiserver


echo "##########==> 生成kubectl证书"
cat > kubernetes/kubectl-csr.json <<EOF
{
  "CN": "clusteradmin",
  "key": {"algo": "ecdsa", "size": 256},
  "names": [{"C": "CN", "L": "ChongQing", "ST": "ChongQing", "O": "system:masters", "OU": "tz"}]
}
EOF

cfssl gencert -ca=rootca/rootca.pem \
-ca-key=rootca/rootca-key.pem \
--config=cfssl-conf.json \
-profile=common kubernetes/kubectl-csr.json | cfssljson -bare kubernetes/kubectl


echo "##########==> 生成kube-controller-manager证书"
cat > kubernetes/kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "hosts": ["127.0.0.1", ${apiserver_hosts}],
  "key": {"algo": "ecdsa", "size": 256},
  "names": [{"C": "CN", "ST": "ChongQing", "L": "ChongQing", "O": "KUBERNETES", "OU": "tz"}]
}
EOF

cfssl gencert -ca=rootca/rootca.pem \
-ca-key=rootca/rootca-key.pem \
--config=cfssl-conf.json \
-profile=common kubernetes/kube-controller-manager-csr.json | cfssljson -bare kubernetes/kube-controller-manager


echo "##########==> 生成kube-scheduler证书"
cat > kubernetes/kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "hosts": ["127.0.0.1", ${apiserver_hosts}],
  "key": {"algo": "ecdsa", "size": 256},
  "names": [{"C": "CN", "ST": "ChongQing", "L": "ChongQing", "O": "KUBERNETES", "OU": "tz"}]
}
EOF

cfssl gencert \
-ca=rootca/rootca.pem \
-ca-key=rootca/rootca-key.pem \
--config=cfssl-conf.json \
-profile=common kubernetes/kube-scheduler-csr.json | cfssljson -bare kubernetes/kube-scheduler

echo "##########==> 生成kube-proxy证书"
cat > kubernetes/kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {"algo": "ecdsa", "size": 256},
  "names": [{"C": "CN", "ST": "ChongQing", "L": "ChongQing", "O": "KUBERNETES", "OU": "tz"}]
}
EOF

cfssl gencert \
-ca=rootca/rootca.pem \
-ca-key=rootca/rootca-key.pem \
--config=cfssl-conf.json \
-profile=common kubernetes/kube-proxy-csr.json | cfssljson -bare kubernetes/kube-proxy


echo "##########==> 传递证书到其他node"
echo $other_ips | xargs -n1 | while read ip
do 
  echo "scp -> $ip"
  scp -r  -o StrictHostKeyChecking=no /opt/cluster/ssl ${ip}:/opt/cluster
done
