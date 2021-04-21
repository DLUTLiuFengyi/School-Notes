### Yarn

独立部署（standalone）模式由spark自身提供计算资源，无需其他框架提供资源，这种方式降低了和第三方资源框架的耦合性。

但spark本身是计算框架而不是资源调度框架。

使用yarn来进行资源调度。

这种模式下，只需要一台主机（master）安装spark环境即可，因为这台机子只负责提交一些基本的配置和jar包，而资源调度则由hadoop+yarn完成，所属者。

| 模式       | Spark安装主机数 | 需启动的进程   | 所属者 | 应用场景 |
| ---------- | --------------- | -------------- | ------ | -------- |
| local      | 1               | 无             | spark  | 测试     |
| standalone | 3               | master及worker | spark  | 单独部署 |
| yarn       | 1               | yarn及hdfs     | hadoop | 混合部署 |

常见端口号

* 运行过程中查看任务情况：4040
* standalone模式中master内部通信服务：7077

* standalone模式中master web ui：8080
* spark历史服务：18080
* hadoop yarn任务运行情况 ui：8088

