本篇均在[**master**]

### RS

vim rs.yaml

```yaml
apiVersion: extensions/v1beta1
kind: ReplicaSet
metadata:
  name: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      labels:
        tier: frontend
    spec:
      containers:
      - name: php-redis
        image: hub.atguigu.com/library/myapp:v1
        env:
        - name: GET_HOSTS_FROM
          value: dns
        ports:
        - containerPort: 80
```

副本数设置为3

labels设置为tier=frontend

kubectl create -f rs.yaml

kubectl get pod

kubectl delete pod -all 

发现被删除-新建-随机数不同-还是3个

kubectl get pod --show-labels

修改标签

kubectl label pod frontend-随机数 tier=frontend1 --overwrite=True

这时候发现frontend变成4个

说明k8s副本数监控是以标签为基础的



### Deployment

Deployment为pod和RS提供了一个声明式方法，用来替代以前的RC来方便的管理应用。

#### 部署一个Nginx应用

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  template:
    metadata:
      labels:
        # rs创建的pod的标签
        app: nginx
    spec:
      containers:
      - name: nginx
        image: hub.atguigu.com/library/myapp:v1
        # image: nginx:1.7.9
        ports:
        # 这里声明端口意义不大，因为是一个扁平化网络
        - containerPort: 80
```

// kubectl create -f http://kubernetes.io/docs/user-guid/nginx-deployment.yaml --record

kubectl apply -f deployment.yaml --record

kubectl get deployment

kubectl get rs

发现deployment会创建对应的rs

kubectl get pod

kubectl get pod -o wide

curl [某个pod显示的ip]

#### 扩容

kubectl scale deployment nginx-deployment --replicas=10

**这里体现出k8s优势，应用的扩容缩非常简单**

此时rs并没有进行版本更新

#### 更新镜像

nginx是容器名

原来镜像是hub.atguigu.com/library/myapp

kubectl set image deployment/nginx-deployment nginx=wangyanglinux/myapp:v2

kubectl get rs

#### 回滚

kubectl rollout undo deployment/nginx-deployment

kubectl get rs

#### 回退Deployment

查看当前更新（回滚）状态

kubectl rollout status deployment nginx-deployment

kubectl rollout history deployment nginx-deployment

##### 删除deployment并重走一次流程

kubectl delete deployment --all

kubectl apply -f deployment.yaml --record

kubectl set image deployment/nginx-deployment nginx=wangyanglinux/myapp:v3

kubectl rollout status deployment nginx-deployment

##### 回到某个历史版本

kubectl rollout undo deployment/nginx-deployment --to-revision=1

