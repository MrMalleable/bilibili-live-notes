# 搭建K8s集群

 环境：windows 10

工具：Vagrant



[Ubuntu19.04部署kubernetes-master_发现美的眼睛-CSDN博客](https://blog.csdn.net/qq_42346414/article/details/89949380)

## 1、使用vagrant启动三台机器

vagrant box add https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cloud-images/bionic/current/bionic-server-cloudimg-amd64-vagrant.box --name ubuntu/bionic



vagrant init ubuntu/bionic





启动好三台机器，修改hostname为master、slave1、slave2

在每台机器修改hosts文件

关闭防火墙 ufw disable

关闭selinux 

sudo apt install selinux-utils

setenforce 0

sudo swapoff -a

sudo vim /etc/sysctl.conf

开启ipv4转发

sudo sysctl -p

防火墙修改FORWARD链默认策略

sudo iptables -P FORWARD ACCEPT

配置iptables参数，使得流经网桥的流量也经过iptables/netfilter防火墙

sudo tee /etc/sysctl.d/k8s.conf <<-'EOF'
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system


 需要在每台机器上面安装docker
 按照官网来
 sudo apt-get update
 sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
使用国内源
curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu \
$(lsb_release -cs) stable"

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io


sudo tee /etc/docker/daemon.json <<- 'EOF'
{

"exec-opts": ["native.cgroupdriver=systemd"],

"registry-mirrors": ["https://5xcgs6ii.mirror.aliyuncs.com"]
}
EOF



sudo systemctl enable docker && sudo systemctl start docker



# 安装指定版本

sudo apt-get update && sudo apt-get install -y apt-transport-https curl

sudo curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -

sudo tee /etc/apt/sources.list.d/kubernetes.list <<-'EOF'
deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main
EOF

sudo apt update

sudo apt-get install -y kubelet=1.22.2-00 kubeadm=1.22.2-00 kubectl=1.22.2-00
sudo apt-mark hold kubelet=1.22.2-00 kubeadm=1.22.2-00 kubectl=1.22.2-00



sudo systemctl enable kubelet && sudo systemctl start kubelet



kubeadm config images list --kubernetes-version=v1.22.2

```sh
k8s.gcr.io/kube-apiserver:v1.22.2
k8s.gcr.io/kube-controller-manager:v1.22.2
k8s.gcr.io/kube-scheduler:v1.22.2
k8s.gcr.io/kube-proxy:v1.22.2
k8s.gcr.io/pause:3.5
k8s.gcr.io/etcd:3.5.0-0
k8s.gcr.io/coredns/coredns:v1.8.4
```



#!/bin/bash
images=(kube-proxy:v1.22.2 kube-scheduler:v1.22.2 kube-controller-manager:v1.22.2 kube-apiserver:v1.22.2 etcd:3.5.0-0 pause:3.5 )
for imageName in ${images[@]} ; do
docker pull registry.aliyuncs.com/google_containers/$imageName
docker tag registry.aliyuncs.com/google_containers/$imageName k8s.gcr.io/$imageName
docker rmi registry.aliyuncs.com/google_containers/$imageName
done

sudo docker pull coredns/coredns:1.8.4
sudo docker tag coredns/coredns:1.8.4   k8s.gcr.io/coredns/coredns:v1.8.4

sudo docker pull xwjh/flannel:v0.14.0
sudo docker tag xwjh/flannel:v0.14.0



sudo kubeadm init --apiserver-advertise-address=192.168.33.10 --pod-network-cidr=172.16.0.0/16 --service-cidr=10.233.0.0/16 --kubernetes-version=v1.22.2

sudo kubeadm init  --pod-network-cidr=172.16.0.0/16 --service-cidr=10.233.0.0/16 --kubernetes-version=v1.22.2

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubeadm join 192.168.33.10:6443 --token m9evqe.7pu5lxgo5dg1u74e \
	--discovery-token-ca-cert-hash sha256:8cfa362bc5bec12e1fca178aa549d8445cd1095da812b96f8318d04b4151da03



sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl restart kubelet
sudo systemctl restart kube-proxy



kubectl apply -f flannel.yml



sudo docker pull quay.io/coreos/flannel:v0.14.0





删除所有的容器

sudo docker ps -a|grep Exited|awk '{print $1}'

sudo docker rm -f `docker ps -a|awk '{print $1}'`



sudo docker ps -a|awk '{print $1}' | sudo xargs docker rm -f

sudo systemctl start kubelet





kubectl proxy --address='0.0.0.0'



腾讯云三台服务器：

10.206.0.6 master

10.206.0.10 slave1

10.206.0.9 slave2 

kubeadm join 10.206.0.6:6443 --token zte7uj.pofhkmwyos2omvsm \
	--discovery-token-ca-cert-hash sha256:035b55a68103a54e4c57654d6d56012a4a8e29001b5aa4d3dc89dd004fced046


# 下载 kube-flannel.yml
wget https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml
# 修改其中net-conf.json的Network参数使其与kubeadm init时指定的 --pod-network-cidr一致, 此次使用的是172.16.0.0/16
vi kube-flannel.yml
# 安装
kubectl apply -f kube-flannel.yml




