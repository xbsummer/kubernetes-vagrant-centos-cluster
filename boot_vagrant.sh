#!/usr/bin/env bash
echo "begin..."

#如果是window系统，需要安装此插件
#vagrant plugin install vagrant-winnfsd 

vagrant destroy -f
vagrant up --no-provision


#生成ssh公钥
> ./.ssh/authorized_keys
vagrant provision --provision-with ssh_keygen

#环境配置（同步时间、关闭防火墙、安装必备软件、系统优化、hosts配置等）
vagrant provision --provision-with env_config 

#下载k8s需要的组件
vagrant provision --provision-with download_soft

#vagrant provision --provision-with cgroupfs_mount

#安装docker
vagrant provision --provision-with docker 

#安装证书工具并生成根证书
vagrant provision --provision-with cfssl

#安装etcd
vagrant provision --provision-with etcd 

#安装kube-apiserver
vagrant provision --provision-with kube_api

#安装kubectl
vagrant provision --provision-with kube_config

#安装controller_manager
vagrant provision --provision-with controller_manager

#安装scheduler
vagrant provision --provision-with scheduler

#安装kubelet
vagrant provision --provision-with kubelet

#安装kube_proxy
vagrant provision --provision-with kube_proxy

#安装calico
vagrant provision --provision-with calico

#安装coredns
vagrant provision --provision-with coredns

#授权证书
vagrant provision --provision-with csr
