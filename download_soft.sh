#!/usr/bin/env bash
export PATH="$PATH:/usr/local/bin"

echo "##########==> 开始下载k8s需要的组件"

[ -d /vagrant/tools ] || mkdir -p /vagrant/tools
cd /vagrant/tools

# 1、 下载docker
docker_version=`grep "docker_version" ../config.yaml | cut -d" " -f2  | sed "s/\n//g"` 
if [ ! -f ./docker-${docker_version}.tgz ]; then
    echo "begin download docker-${docker_version}..."
    url="https://download.docker.com/linux/static/stable/x86_64/docker-${docker_version}.tgz"
    wget $url
    echo "end download docker-${docker_version}"
fi

# 2、 下载证书
cfssl_version=`grep "cfssl_version" ../config.yaml | cut -d" " -f2  | sed "s/\n//g"` 
if [ ! -f ./cfssl_${cfssl_version:1}_linux_amd64 ]; then
  echo "begin download cfssl-${cfssl_version}..."
  url="https://github.com/cloudflare/cfssl/releases/download/${cfssl_version}/cfssl_${cfssl_version:1}_linux_amd64"
  wget $url
  echo "end download cfssl-${cfssl_version}..."
fi

if [ ! -f ./cfssl-certinfo_${cfssl_version:1}_linux_amd64 ]; then
  echo "begin download cfssl-certinfo_${cfssl_version}..."
  url="https://github.com/cloudflare/cfssl/releases/download/${cfssl_version}/cfssl-certinfo_${cfssl_version:1}_linux_amd64"
  wget $url
  echo "end download cfssl-certinfo_${cfssl_version}..."
fi

if [ ! -f ./cfssljson_${cfssl_version:1}_linux_amd64 ]; then
  echo "begin download cfssljson-${cfssl_version}..."
  url="https://github.com/cloudflare/cfssl/releases/download/${cfssl_version}/cfssljson_${cfssl_version:1}_linux_amd64"
  wget $url
  echo "end download cfssljson-${cfssl_version}..."
fi

# 3、 下载etcd
etcd_version=`grep "etcd_version" ../config.yaml | cut -d" " -f2 | sed "s/\n//g"` 
if [ ! -f ./etcd-${etcd_version}-linux-amd64.tar.gz ]; then
  echo "begin download etcd-${etcd_version}..."
  url="https://github.com/etcd-io/etcd/releases/download/${etcd_version}/etcd-${etcd_version}-linux-amd64.tar.gz"
  wget $url
  echo "end download etcd-${etcd_version}"
fi

# 4、 下载kubernetes_release
kubernetes_release_version=`grep "kubernetes_release_version" ../config.yaml | cut -d" " -f2 | sed "s/\n//g"` 
if [ ! -f ./kubernetes-server-linux-amd64.tar.gz ]; then
  echo "begin download kubernetes_release-${kubernetes_release_version}..."
  url="https://storage.googleapis.com/kubernetes-release/release/${kubernetes_release_version}/kubernetes-server-linux-amd64.tar.gz"
  wget $url
  echo "end download kubernetes_release-${kubernetes_release_version}"
fi

# 5、 下载calico插件
calico_version=`grep "calico_version" ../config.yaml | cut -d" " -f2 | sed "s/\n//g"` 
if [ ! -f ./calico.yaml ]; then
  echo "begin download calico-${calico_version}..."
  url="https://docs.projectcalico.org/${calico_version}/manifests/calico.yaml"
  wget $url
  echo "end download calico-${calico_version}..."
fi



# 5、 下载coredns,重命名为coredns.yaml
#https://github.com/coredns/deployment/blob/master/kubernetes/coredns.yaml.sed
echo "##########==> 结束下载k8s需要的组件"