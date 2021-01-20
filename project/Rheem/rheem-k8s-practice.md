### Kubernetes命令

#### 进入容器

kubectl exec -n argo -it clic-shell-test /bin/bash

-it 交互，-- 固定格式，后接运行命令

`kubectl exec [pod名字] -c [容器名字] -it -- /bin/sh`

`kubectl exec [pod名字] -c [容器名字] -it -- rm -rf /usr/xxx/xxx.html`

新建一个index1.html并填入内容

echo "123" >> index1.html

#### 删除pod

`kubectl delete pod [pod名字]`

`kubectl delete pod --all`

#### 删除svc

`kubectl delete svc [svc1名字] [svc2名字] ...`

#### 根据yaml创建pod

`kubectl create -f ini-pod.xml`

#### 根据yaml修改pod

`kubectl apply -f ini-pod.xml`

#### 查看pod中所有容器名字

Use 'kubectl describe pod/hdfs-namenode-0 -n argo' to see all of the containers in this pod

---

### Rheem on k8s

```shell
# 获取所有pods
kubectl get pods --all-namespaces
# 获取所有pods中使用的images（uniq表示结果中去除重复的images）
kubectl get pods --all-namespaces -o jsonpath="{..image}" |\
tr -s '[[:space:]]' '\n' |\
sort |\
uniq -c
```

**修改image（现在不需要了，改成将所需文件都放在挂载的nfs或hdfs）**

```shell
# 终端1
sudo docker images
# 先由spark-env:v0镜像运行一个容器
sudo docker run -it spark-env:v0 /bin/bash
(sudo docker run -it --name="spark-env-watch" spark-env:v0  /bin/bash)
cd /root
mkdir results

# 终端2
sudo docker ps
# 往容器里添加几个文件（此时会在/root/目录(~目录)下粘贴一个主机的jars文件夹）
sudo docker cp jars/ 817e0b463407:/root/

# 终端1
# 退出（结束容器）
exit
```

**封装新image**

```shell
# 终端1
sudo docker ps -a
sudo docker commit -m "add rheem jars" -a "lfy" 817e0b463407 rheem-spark:v1
```

**删除**

```shell
sudo docker stop [容器id]
sudo docker rm [容器id]
sudo docker rmi [镜像id]
```

**重启容器**

```shell
sudo docker start [容器id]
sudo docker exec -it [容器id] /bin/bash
```



**编写yaml文件**

```shell
vim job-rheem-pagerank-soc.yml
```

```yml
apiVersion: v1
kind: Pod
metadata:
  name: rheem-pagerank-soc-pod
spec:
  volumes:
  - name: nfs-volume
    persistentVolumeClaim:
      claimName: pvc-nfs
  containers:
  - name: rheem-pagerank-soc
    image: rheem-spark:v1
    imagePullPolicy: IfNotPresent
    command: ["java"]
    args:  ["-jar", "/data/lfy/jars/pagerank_soc.jar", "basic-graph,java,java-conversion,java-graph,spark,spark-graph,graphchi", "file:/data/datasets/pagerank_soc_LiveJournal.txt", "1",  "/data/lfy/results/pagerank_result.txt"]
    volumeMounts:
    - mountPath: /data
      name: nfs-volume
```

**on k8s**

```shell
# 运行yaml文件，创建pod
kubectl create -f job-rheem-pagerank-soc-k8s.yml -n argo
# 查看pod详情
kubectl describe pod rheem-pagerank-soc-k8s-pod -n argo
# 查看所有pod的状态
kubectl get pod -n argo -o wide
# 查看pod中容器的日志（该pod只有一个容器）
kubectl logs rheem-pagerank-soc-k8s-pod -n argo
# 再运行一次yaml，替代原来的pod
kubectl replace --force -f job-rheem-pagerank-soc-k8s.yml -n argo
```

```shell
# 查看pod中容器的日志
# 方法1 在执行这个pod的主机上
sudo docker logs 8715e3737147
-t 加入时间戳
-f 不停追加
--tail 3 只看倒数三行

# 方法2 在k8s server上
kubectl logs rheem-pagerank-soc-k8s-pod -n argo

# 删除pod
kubectl delete pod rheem-pagerank-soc-k8s-pod -n argo
```

```shell
# 删除镜像
sudo docker rmi [镜像id]
# 删除容器
sudo docker rm [容器id]
```

#### Hadoop

```shell
# 进入hdfs-namenode-0这个pod
kubectl exec -n argo -it hdfs-namenode-0 /bin/bash

# 查看当前目录信息
hdfs dfs -ls /

exit
```





---

### Rheem  on non-k8s

#### Java Properties

```properties
rheem.java.cores = 56
```

#### Spark Properties

```properties
spark.master = spark://ip:8077
#spark.master = spark://spark-master-svc:7077 #k8s
spark.app.name = Rheem App
spark.ui.showConsoleProgress = false
spark.driver.memory = 50g
spark.executor.memory = 108g
spark.driver.maxResultSize=24g

rheem.spark.cpu.mhz = 2700
rheem.spark.machines = 3
rheem.spark.cores-per-machine = 56
```

java.net.URISyntaxException: Illegal character in authority at index 8: spark://ip:8077

原因：spark://ip:8077后多了一个空格



#### WordCount

##### "The great Gatsby" excerpts

**java**

```shell
java -jar ~/jars/wordcount.jar "java" "file:/home/lfy/data/wordcount_1G.txt" "/home/lfy/results/wordcount_result.txt"
```

**spark**

```shell
./spark-submit --class com.github.dlut.wordcount.java.WordCount ~/jars/wordcount.jar "java,spark" "file:/home/lfy/data/wordcount_1G.txt" "/home/lfy/results/wordcount_result.txt"
```



#### PageRank

##### 知乎粉丝数据集 60MB

节点数 459199   边数 4612110

**java**

迭代32次，用时18s，近似收敛

```shell
java -jar pagerank.jar "basic-graph,java,java-conversion,java-graph,graphchi" "file:/nfs/data/datasets/graph_test_dqh/dqh_graph_test.csv" 32 "/nfs/data/lfy/results/pagerank_result.txt"
```

**spark**

迭代32次，用时107.87s，近似收敛

```shell
./spark-submit --class com.github.dlut.pagerank.scala.PageRank  ~/jars/pagerank.jar "basic-graph,java,java-conversion,java-graph,spark,spark-graph,graphchi" "file:/home/lfy/data/dqh_graph_test.csv" 32 "/home/lfy/results/pagerank_result.txt"
```



##### Stanford LiveJournal social network 1.06GB

节点数 4847571   边数 68993773

**java**

迭代10次，用时207s

迭代15次，用时256.13s，近似收敛

```shell
java -jar pagerank_soc.jar "basic-graph,java,java-conversion,java-graph,graphchi" "file:/nfs/data/datasets/pagerank_soc_LiveJournal.txt" 10 "/nfs/data/lfy/results/pagerank_result.txt"
```

**spark**

迭代15次，用时196.7s

```shell
./spark-submit --class com.github.dlut.pagerank.scala.PageRank  ~/jars/pagerank_soc.jar "basic-graph,java,java-conversion,java-graph,spark,spark-graph,graphchi" "file:/home/lfy/data/pagerank_soc_LiveJournal.txt" 15 "/home/lfy/results/pagerank_result.txt"
```



---

### CLIC

```shell
java -jar .\wc_java.jar --udfPath=D:/2020project/data/udfs/WordCountUDF.class --dagPath=D:/2020project/data/yaml/physical-dag-212742111.yml

java -jar ~/jars/wc_java.jar --udfPath=/home/lfy/data/WordCountUDF.class --dagPath=/home/lfy/codes/yaml/physical-dag-wc-java-local-1g.yml

./spark-submit --master=spark://10.176.24.160:8077 --class fdu.daslab.executable.spark.ExecuteSparkOperator ~/jars/wc_spark.jar --udfPath=/home/lfy/data/WordCountUDF.class --dagPath=/home/lfy/codes/yaml/physical-dag-wc-spark-local-1g.yml
```



---

### HDFS

```shell
hdfs dfs -ls \

# 创建文件夹
hdfs dfs -mkdir /data/datasets/wordcount
# 上传
hdfs dfs -put ~/data/wordcount_1G.txt /data/datasets/wordcount
# 下载
hdfs dfs -get /data/datasets/wordcount/wordcount_1G.txt ~/results

String hdfsPath = "hdfs://ip:port/data/datasets/wordcount/wordcount_1G.txt"
```

https://www.jianshu.com/p/52506c7bf662



---

#### London crime

```shell
java -Xmx50g -jar london.jar java hdfs://10.176.24.160:9820/tzw/london_crime/london_crime_0.45g.csv

./spark-submit --class com.github.dlut.london.SparkJavaTask ~/jars/london.jar "spark" hdfs://10.176.24.160:9820/tzw/london_crime/london_crime_0.45g.csv

# 考虑java平台时，需要特别声明--driver-memory，以避免堆溢出
# 此参数等同于java里的-Xmx，含义是最大堆大小
./spark-submit --driver-memory 50G --class com.github.dlut.london.SparkJavaTask ~/jars/london.jar "java" hdfs://10.176.24.160:9820/tzw/london_crime/london_crime_3.5g.csv
```

我们使用java -X可以看到java的-X系列的参数

* Xmx: memory max

  最大可以从操作系统中获取的内存数量

* Xms: memory start

  程序启动的时候从操作系统中获取的内存数量

`java -cp . -Xms80m -Xmx256m `

说明这个程序启动的时候使用80m的内存，最多可以从操作系统中获取256m的内存



| 数据量 | spark  | java   | spark + java |
| ------ | ------ | ------ | ------------ |
| 450M   | 24068  | 8275   | 8307         |
| 900M   | 24593  | 13206  | 13495        |
| 1.8G   | 24967  | 25666  | 24906        |
| 3.5G   | 26782  | 51958  | 49990        |
| 7G     | 29792  | 97700  | 97834        |
| 14G    | 69166  | 191746 | 187278       |
| 28G    | 197223 | 394137 | 366560       |

