### 问题本质

跨进程通信

### 思想核心

用代理proxy隐藏跨主机通信中数据序列化反序列化等细节

不需要关心底层封装和协议的调用，只需要关心具体调用的业务逻辑

### RPC框架

* webservice

  基于http+xml通信

* dubbo

* thrift

* http

  基于request/response（封装请求/响应消息），走传输层到tomcat接收

* hessian

* grpc

### 实现

#### 方式1

rpc-client   ---调用类 参数 方法--->   rpc-server

缺点：

当rpc-server数量很多时（集群）

* 客户端要获得服务调用的话，要写定host和port，还要写负载均衡算法去选择合适的节点
* 集群中某个节点出现问题，服务down了，而客户端还会选择这台机子，则客户端发送到这台机子上的请求都会失败

解决方法：

Dubbo + Zookeeper + 微服务

dubbo是一个rpc通信框架，基于zookeeper去实现的服务注册和发现

容错？限流？

---

### 无关笔记

TCP/UDP -> Netty -> Dubbo