## Install ubuntu and build network between vms

Reference

https://blog.csdn.net/yamadeee/article/details/103600629

https://zhuanlan.zhihu.com/p/166348043



linux-live-server.iso attentions:

* when the new vm is installing, x represents yes
* 



[vm linux]

Keep the default network settings (NAT)

ping www.baidu.com

#### ssh.server

Watch whether install ssh.server

sudo service ssh start

sudo apt-get install openssh-server

Edit the properties, permit the root user to login by ssh
     a): sudo vi /etc/ssh/sshd_config
     b): PermitRootLogin prohibit-password --
     c): PermitRootLogin yes -- 添加
      d): :wq -- 保存

sudo service ssh restart



Watch vm ip addr

(sudo apt install net-tools)

ifconfig



[local windows]

ping 10.177.39.76



[vm linux]

Watch the user name for xshell login

who



[local windows]

Use xshell

ssh, ip, 22, liu 123456



## Begin Install k8s

Reference 

https://blog.csdn.net/wangchunfa122/article/details/86529406



### Set basic network

Disable swap

sudo swapoff -a

Meanwhile delete the line includes swap in /etc/fstab



Close firewall

sudo apt install firewalld

sudo systemctl stop firewalld

sudo systemctl disable firewalld



Disable selinux

sudo apt install selinux-utils

setenforce 0 (if display "...is disabled", means that selinux has been closed)



Set domain name

sudo vi /etc/hosts

192.168.100.128 master01

192.168.100.129 node01

192.168.100.131 node02



### Install Docker

Install relative tools

sudo apt-get update && sudo apt-get install -y apt-transport-https curl

Add secret key

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

Install docker

sudo apt-get install docker.io -y

Check docker version

sudo docker version

Start docker service

sudo systemctl enable docker

sudo systemctl start docker

sudo systemctl status docker

(use :q to quit the status info display)

Configure the aliyun mirror link

sudo vi  /etc/docker/daemon.json 

```json
{    
	"registry-mirrors": ["https://alzgoonw.mirror.aliyuncs.com"],    
	"live-restore": true 
}
```

Note that the daemon.json file didn't exist before and will be create by us now.

Restart docker service

sudo systemctl daemon-reload

sudo systemctl restart docker



### Install K8S

#### Get the gpg key from official k8s (This step is abandoned now)

Set secret key

sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

But meet error, try to reference this

https://blog.csdn.net/wiborgite/article/details/52840371

But meet connect error, try to visit https://packages.cloud.google.com/apt/doc/apt-key.gpg in external PC (windows) by using ladder and download the key file (apt-key.gpg). Then transfer it to the vm.



#### Transfer files from PC to VM by Xshell (This step is abandoned now)

rz

If no rz, download

sudo apt install lrzsz

Then load the key

rz 

sudo apt-key add apt-key.gpg 

Update apt-get

sudo apt-get update



#### Get the gpg key

Attention that the download sources of apt-get  is defined by /etc/apt/sources.list (file) and we need to add a new source file about k8s in sources.list.d (folder)

Reference 

https://www.linshuaishuai.com/article/p/2020331103129

To get the mirror from aliyun, we need to get the key first

sudo vi /etc/apt/sources.list.d/kubernetes.list

```list
deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main
```

sudo apt-get update

sudo curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -



#### Install kubelet, kubeadm, kubectl

sudo apt-get install kubelet

sudo apt-get install kubeadm

In fact, the kubectl and kubernetes-cni have been installed while installing kubelet and adm

sudo apt-get install kubectl

sudo apt-get install kubernetes-cni

**Now we have installed k8s's relative software**

sudo systemctl enable kubelet



#### Set the properties

Add PATH in /etc/profile

sudo vi /etc/profile

```
export KUBECONFIG=/etc/kubernetes/admin.conf
```

Restart kubelet

sudo systemctl daemon-reload

sudo systemctl restart kubelet



#### Install k8s package from aliyun mirror

**Pull the docker images which kubeadm needs**

Note that the images that kubeadm needs will be downloaded from gcr.io automatically. But gcr.io will be walled, so we have to pull images from other image station and tag gcr TAG on there images. Use command below to see needed images and version.

kubeadm config images list

```Linux
k8s.gcr.io/kube-apiserver:v1.19.2
k8s.gcr.io/kube-controller-manager:v1.19.2
k8s.gcr.io/kube-scheduler:v1.19.2
k8s.gcr.io/kube-proxy:v1.19.2
k8s.gcr.io/pause:3.2
k8s.gcr.io/etcd:3.4.13-0
k8s.gcr.io/coredns:1.7.0
```

Pull the images from aliyun

sudo docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.19.2

sudo docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.19.2

sudo docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.19.2

sudo docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.19.2

sudo docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2

sudo docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.4.13-0

sudo docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.7.0

Tag the images

sudo docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.19.2 k8s.gcr.io/kube-apiserver:v1.19.2

sudo docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.19.2 k8s.gcr.io/kube-controller-manager:v1.19.2 

sudo docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.19.2 k8s.gcr.io/kube-scheduler:v1.19.2 

sudo docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.19.2 k8s.gcr.io/kube-proxy:v1.19.2 

sudo docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 k8s.gcr.io/pause:3.2 

sudo docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.4.13-0 k8s.gcr.io/etcd:3.4.13-0 

sudo docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.7.0 k8s.gcr.io/coredns:1.7.0 



#### Start to build the cluster

Close swap and firewall

sudo swapoff -a

sudo ufw disable

**[master01]**

Initial api-server

sudo kubeadm init --apiserver-advertise-address=192.168.100.128

```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.100.128:6443 --token cx3qis.vegg130yfgosuyka \
    --discovery-token-ca-cert-hash sha256:84b382c388d683b638917f3f2fdafe288a5fa3e2d42965baa5859260b9a024f9
```

Copy properties to user floder

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

Configure network unit flannel

sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

**[node01] [node02]**

sudo kubeadm join 192.168.100.128:6443 --token cx3qis.vegg130yfgosuyka \
    --discovery-token-ca-cert-hash sha256:84b382c388d683b638917f3f2fdafe288a5fa3e2d42965baa5859260b9a024f9

mkdir .kube

**[master01]**

Check the status

sudo kubectl get nodes

sudo kubectl get pods -n kube-system

Copy api-server property from master to node

sudo scp /etc/kubernetes/admin.conf liu@node01:$HOME/.kube/config

sudo scp /etc/kubernetes/admin.conf liu@node02:$HOME/.kube/config

**[node01] [node02]**

sudo cp -i $HOME/.kube/config /etc/kubernetes/admin.conf

echo "export KUBECONFIG=$HOME/.kube/config" >> ~/.bash_profile

source ~/.bash_profile