#### 历史服务

spark-shell停止后，ip:4040就看不到历史任务的运行情况，所以需要配置历史服务器记录任务运行情况。

* 修改`spark-defaults.conf.template`文件名为`spark-defaults.conf`

* vim spark-defaults.conf，配置日志存储路径

  ```properties
  spark.eventLog.enabled    true
  spark.eventLog.dir    hdfs://ip:8020/directory
  ```

  ```properties
  sbin/start-dfs.sh
  hadoop fs -mkdir /directory
  ```

* vim spark-env.sh

  ```shell
  export SPARK_HISTORY_OPTS="
  -Dspark.history.ui.port=18080"
  -Dspark.history.fs.logDirectory=hdfs://ip:8020/directory
  -Dspark.history.retainedApplications=30"
  ```

  启动时

  ```shell
  ./start-history-server.sh
  ```

  