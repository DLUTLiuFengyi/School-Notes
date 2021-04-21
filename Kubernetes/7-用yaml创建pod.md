### 集群资源分类
#### 名称空间级别
例如k8s系统本身组件放在kube-system名称空间，用`kubectl get pod -n default`看不到。
#### 集群级别：
role
#### 元数据型级别：
提供一个指标，介于两者之间，有自己的特点。HPA可以通过cpu利用率进行扩展。



k8s中所有内容都抽象为资源，资源实例化之后称为对象。

#### 工作负载型资源

Pod、ReplicaSet（通过标签选择控制副本数）、deployment、StatefulSet、DaemonSet、Job和CronJob（批处理任务）
#### 服务发现及负载均衡资源
#### 配置与存储型资源

Volume（存储卷）、CSI（容器存储接口，扩展第三方）

#### 特殊类型的存储卷

ConfigMap（当配置中心来使用的资源类型）、Secret（加密方案存储数据）、DownwardAPI（把外部环境中的信息输出给容器）

#### 集群级资源

Namespace、Node

#### 元数据型资源

HPA



### yaml-资源清单
使用yaml来创建符合期望的pod

查看pod的yaml模板
`kubectl explain pod`
`kubectl explain pod.apiVersion`

------------------------------------------------------------------------------------
### 创建一个pod
master01
`vim pod.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels: 
    app: myapp
    version: v1
spec:
  containers:
  - name: app
    image: hub.aiguigu.com/library/myapp:v1
  # 这里会遇到端口冲突问题，所以先将test容器注释
  #- name: test
    #image: hub.aiguigu.com/library/myapp:v1
```

`kubectl apply -f pod.yaml`
`kubectl get pod`
查看pod信息
`kubectl describe pod myapp-pod`
查看pod中的容器的日志 -c指定容器叫什么
`kubectl log myapp-pod -c [容器的name]`

删除pod
`kubectl delete  pod myapp-pod`
根据yaml又新建一个pod
`kubectl create -f pod.yaml`
`kubectl get pod -o wide`