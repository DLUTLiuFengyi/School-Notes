### HA 

一般用Zookeeper

| 0         | 1         | 2         |
| --------- | --------- | --------- |
| master    | master    |           |
| zookeeper | zookeeper | zookeeper |
| worker    | worker    | worker    |

* 启动zookeeper

* vim spark-env.sh

  ```sh
  # 先注释
  # SPARK_MASTER_HOST=...
  # SPARK_MASTER_PORT=...
  
  SPARK_MASTER_WEBUI_PORT=8989 # 为了防止跟zk的8080端口冲突
  export SPARK_DAEMON_JAVA_OPTS="
  -Dspark.deploy.recoveryMode=ZOOKEEPER
  -Dspark.deploy.zookeeper.url=ip0,ip1,ip2
  -Dspark.deploy.zookeeper.dir=/spark"
  ```

* ip1启动集群 

  `./start-all.sh`

  或者常规启动

* ip2单独启动master

  `./start-master.sh`

#### 使用

```shell
./spark-submit ... --master spark://ip0:8077,ip1:8077
```

