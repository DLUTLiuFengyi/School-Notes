## Install flink in Windows

在本地配置flink环境参考

https://blog.csdn.net/x976269167/article/details/105700963



* 在下面地址下载.tgz后缀文件，解压到本地文件夹

  https://archive.apache.org/dist/flink/flink-1.8.0/

* 打开cmd，在bin文件夹下执行

  `./start-cluster.bat`

* 访问localhost:8081
* `./flink.bat run ../examples/batch/WordCount.jar`



以scala shell方式打开

`./start-scala-shell.sh local`



注意：https://blog.csdn.net/qq_36932624/article/details/109721140