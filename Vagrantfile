# -*- mode: ruby -*-
# vi: set ft=ruby :
# on win10, you need `vagrant plugin install vagrant-vbguest --plugin-version 0.21` and change synced_folder.type="virtualbox"
# reference `https://www.dissmeyer.com/2020/02/11/issue-with-centos-7-vagrant-boxes-on-windows-10/`


Vagrant.configure("2") do |config|
  config.vm.box_check_update = false
  config.vm.provider 'virtualbox' do |vb|
    vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
  end  
  config.vm.synced_folder ".", "/vagrant", type: "nfs"
  config.vm.box = "centos/8"
  config.vm.box_version = "2105.0"


  #生成node
  resources = [
    {seq: 1, ip: "192.168.56.100", name: "k8s-master-01", tag: "master", etcd: true, etcd_seq: 1},   
    {seq: 2, ip: "192.168.56.101", name: "k8s-node-01", tag: "node", etcd: true, etcd_seq: 2},  
    {seq: 3, ip: "192.168.56.102", name: "k8s-node-02", tag: "node", etcd: true, etcd_seq: 3}
  ]         

  #etcd集群一般最少3台，这里1台master，2台node
  etcds = resources.select{|item| item[:etcd]}
  hosts = resources.map{|m| [m[:ip], m[:name]]}.flatten()
  masters = resources.select{|item| item[:tag] == "master"}

  resources.each do |item|
    name = item[:name]
    ip = item[:ip]
    config.vm.define "#{name}" do |node|
      node.vm.hostname = "#{name}"
      node.vm.network "private_network", ip: "#{ip}"
      node.vm.provider "virtualbox" do |vb|
        vb.memory = "3072"
        vb.cpus = 1
        vb.name = "#{name}"
      end

      # 执行etcd的安装
      if item[:etcd]
        etcd_cluster = etcds.reduce(""){|s, c| format("%s,etcd%02d=https://%s:2380", s, c[:etcd_seq], c[:ip])}[1..-1]
        etcd_name = format("etcd%02d", item[:etcd_seq])
        node.vm.provision "shell", path: "etcd.sh", args: [etcd_name, etcd_cluster], name: "etcd"
      end
      
      # master安装apiServer, controllerManager, kubectl, scheduler
      if item[:tag] == "master"        
        etcd_servers = etcds.map{|m| "https://" + m[:ip] + ":2379"}.join(",")
        node.vm.provision "shell", path: "kube_api.sh", name: "kube_api", args: [etcd_servers]

        
        node.vm.provision "shell", path: "controller_manager.sh", name: "controller_manager"
        node.vm.provision "shell", path: "scheduler.sh", name: "scheduler"
      end

      # node安装kubelet, kube_proxy
      if item[:tag] == "node"
        node.vm.provision "shell", path: "kube_proxy.sh", name: "kube_proxy"
      end            

      if item[:seq] == 1
        node.vm.provision "shell", path: "calico.sh", name: "calico"
        node.vm.provision "shell", path: "coredns.sh", name: "coredns"
        node.vm.provision "shell", path: "download_soft.sh", name: "download_soft"

        etcd_ips = etcds.reduce(""){|s, c| format("%s, \"%s\"", s, c[:ip])}[1..-1]
        apiserver_hosts = masters.reduce(""){|s, c| format("%s,\"%s\"", s, c[:ip])}[1..-1]
        other_ips = resources.select{|m|m[:ip] != item[:ip]}.map { |m| m[:ip] }.join(" ")
        node.vm.provision "shell", path: "cfssl.sh", name: "cfssl", args: [etcd_ips, apiserver_hosts, other_ips]
        node.vm.provision "shell", path: "kube_config.sh", name: "kube_config", args: [masters.first()[:ip], other_ips]

        node.vm.provision "shell", name: "csr", inline: <<-shell
          export PATH="$PATH:/usr/local/bin"
          echo "begin create clusterrolebinding..."
          kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
          echo "end create clusterrolebinding..."

          kubectl get csr --ignore-not-found=true | grep -i pending | awk '{print $1}' | while read name; do kubectl certificate approve $name; done

          while true
          do
            echo "获取待授权的csr..."
            if (( `kubectl get csr --ignore-not-found=true | wc -l ` > 0 )); then       
              kubectl get csr --ignore-not-found=true | grep -i pending | awk '{print $1}' | while read name; do kubectl certificate approve $name; done
              kubectl get csr 
              break
            fi
            sleep 10
          done
        shell
      end
    end
  end

  config.vm.provision "shell", path: "kubelet.sh", name: "kubelet"
  config.vm.provision "shell", path: "ssh_keygen.sh", name: "ssh_keygen"
  config.vm.provision "shell", path: "env_config.sh", name: "env_config", args: hosts
  config.vm.provision "shell", path: "docker.sh", name: "docker" 
  #config.vm.provision "shell", path: "cgroupfs_mount.sh", name: "cgroupfs_mount" 
end
