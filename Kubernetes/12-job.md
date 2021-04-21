本篇主要在[**master**]

### Job

vim job.yaml

```yaml
apiVersion: batch/v1
kind: Job
metadata: 
  name: pi
spec:
  template: 
    metadata:
      # pod名字叫pi
      name: pi
    spec:
      containers:
      # 容器名字也叫pi
      - name: pi
        image: perl
        # 通过perl语言进行圆周率计算
        # 小数点后2000位
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      # 永远不重启
      restartPolicy: Never
```

kubectl create -f job.yaml

看pod执行到哪一步了

[pod名字]：pod名+随机序列号

kubectl describe pod [pod名字]

kubectl get job

#### 镜像下载太慢，本地导入【新知识】

rz

选择perl.tar.gz

tar -zxvf perl.tar.gz

解压为.tar文件

##### docker load -i perl.tar

**将镜像包传到子节点的根目录**

**scp perl.tar root@k8s-node01:/root/**

等其传送结束

**scp perl.tar root@k8s-node02:/root/**

在[**node01**]也导入一下

docker load -i perl.tar

在[**node02**]也导入一下

docker load -i perl.tar

[**master**]

pi的pod失败了很多次，需要先将其删除

kubectl delete pod pi-序列号

kubectl get job

发现pi已重启

kubectl log pi-序列号

发现输出了2000位的圆周率 