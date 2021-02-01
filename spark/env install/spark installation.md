### 服务器安装spark

下载spark-2.4.5-bin-hadoop2.7.tgz

http://archive.apache.org/dist/spark/spark-2.4.5/

server主机

```shell
tar -zxvf spark-2.4.5-bin-hadoop2.7.tgz

cd spark-2.4.5-bin-hadoop2.7/conf/
mv slaves.template slaves
vim slaves # 添加slave主机ip

mv spark-env.sh.template spark-env.sh
vim spark-env.sh
SPARK_MASTER_IP=xxx
SPARK_MASTER_PORT=8077 # defualt 7077
SPARK_MASTER_WEBUI_PORT=9080 # default 8080

cd ~
scp -r spark-2.4.5-bin-hadoop2.7/ xxx1:/home/xxx/
scp -r spark-2.4.5-bin-hadoop2.7/ xxx2:/home/xxx/
```

运行

```shell
# server /sbin
./start-master.sh

# slaves /sbin
./start-slave.sh spark://xxx:8077

# 将master也设为worker节点
# 在所有主机的conf/
vim slaves
# 添加master的ip
# 在master也执行
./start-slave.sh spark://xxx:8077
```

停止

```shell
# server /sbin
./stop-master.sh

# slaves /sbin
./stop-slave.sh
```



#### IDEA连接远程Spark集群

https://blog.csdn.net/weixin_38493025/article/details/103365712?utm_medium=distribute.pc_relevant.none-task-blog-BlogCommendFromBaidu-1.control&depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromBaidu-1.control

