有一个结构

前端一个nginx

后端三个php-fpm

底线是一个mysql

先部署一个deployment，对应nginx，副本数为1

再部署一个deployment，对应php-fpm，副本数为3

再用statefulset部署一个mysql

在pod中可以调用不同的php-fpm的地址信息，达到对外暴露、负载均衡功能

但有问题

如果有一天1号php down了，deployment会启动新的php，但ip更改了，就很麻烦。

### SVC

一个pod的逻辑分组，一种可以访问它们的策略——通常称为微服务（每一个svc可以理解为一组微服务）。service能通过标签label selector匹配访问到一组pod。

svc负责检测它所匹配的pod的状态信息。svc可理解为一个新的对象。例如创建一个php-svc，其根据标签匹配到三个不同的php的pod，把pod信息记录在svc负载队列中。Nginx的配置信息只要指定到svc的配置信息即可，后续php的变化会同步到svc配置信息中。后端的pod不管是扩容还是更新都不会对nginx造成影响。

并且一组中的某个pod down了后，新建的pod还会被加到svc的队列中。

#### 限制

只提供4层负载均衡能力，没有7层功能，就是说只能基于ip地址和端口进行转发实现负载均衡，不能通过主机名或域名的方案进行负载均衡。

#### 类型

* ClusterIp：默认类型，自动分配一个仅cluster内部可以访问的虚拟ip

* NodePort：在clusterip基础上为service在每台机器上绑定一个端口（可以被外部直接访问），这样就能通过<nodeip>:nodeport来访问该服务

  在node01节点开启30001端口，外部访问30001相当于访问svc内部定义的后端端口80，就是说相当于访问3个不同服务（pod）的80端口，并且node02对外暴露的也是30001端口。意味着在外部（client与k8s集群中间）加一个负载均衡调度器，比如说nginx，其后端节点写到30001，和另一个节点的30001，这就实现了真正的负载均衡效果。客户端client访问nginx，nginx反向代理到其中一个node。

* LoadBalancer：在NodePort基础上借助cloud provider创建一个外部负载均衡器，并将请求转发到<nodeip>:nodeport

  上面的前端的负载均衡器（nginx）不需要具体设置了，只需要引入云供应商给我们去暴露一个服务接口，并且把对应暴露端口30001接入，就可以负载均衡。收费。

* ExternalName：把集群外部的服务引入集群内部来，在集群内部直接使用。没有任何类型代理被创建，需要k8s1.7或更高版本的kube-dns

  mysql-svc，内部写上需要访问的外部服务的ip地址和端口，这样集群内部的nginx pod（deployment）只要访问svc即可，而外部变化时只要更新mysql-svc即可。

#### 主要组件

首先，apiserver监听服务和端点，通过kube-proxy去监控，后者负责去监控对应的匹配的pod的信息，把信息写入iptables规则中。外部客户端访问svc时，其实访问的是iptables规则，被导向到后端（pod）的地址信息。

* 客户端访问到节点是通过iptables实现的
* iptables规则是通过kube-proxy写入的
* apiserver通过监控kube-proxy进行所谓的服务和端点信息的发现
* kube-proxy通过pod的标签判断端点信息是否已经写入svc的endpoint端点信息中

