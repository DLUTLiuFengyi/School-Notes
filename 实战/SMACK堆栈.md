使用SMACK堆栈进行快速数据分析

**SMACK堆栈**

SMACK堆栈各部分如下：

1. Spark作为一个通用、快速、内存中的大数据处理引擎；
2. Mesos作为集群资源管理器；
3. Akka作为一个基于Scala的框架，允许我们开发容错、分布式、并发应用程序；
4. Cassandra作为一个分布式、高可用性存储层；
5. Kafka作为分布式消息代理/日志。

**Apache Spark**
Apache Spark已经成为一种“大数据操作系统”。数据被加载并保存到簇存储器中，并且可以被重复查询。这使得Spark对机器学习算法特别有效。Spark为批处理、流式处理（以微批处理方式）、图形分析和机器学习任务提供统一的接口。

**Apache Mesos**

Apache Mesos是一个开源的集群管理器，它允许跨分布式应用程序的高效资源隔离和共享。在Mesos中，这样的分布式应用程序被称为框架。

**Akka**

Akka是构建在JVM上运行的并发程序框架。强调一个基于actor的并发方法：actors被当作原语，它们只通过消息而不涉及共享内存进行通信。响应消息，actors可以创建新的actors或发送其他消息。actor模型由Erlang编程语言编写，更易普及。

**Apache Cassandra**

Cassandra是一个分布式、面向列的NoSQL数据存储，类似于Amazon的Dynamo和Google的BigTable。与其他NoSQL数据存储相反，它不依赖于HDFS作为底层文件系统，具有无主控架构，允许它具有几乎线性的可扩展性，并且易于设置和维护。Cassandra的另一个优势是支持跨数据中心复制（XDCR）。跨数据中心复制实际上有助于使用单独的工作负载和分析集群。

根据固定分区键，数据在Cassandra集群的节点上分割。其架构意味着它没有单点故障。根据CAP定理，我们可以在每个表的基础上对一致性和可用性进行微调。

**Apache Kafka**

在SMACK堆栈内，Kafka负责事件传输。Kafka集群在SMACK堆栈中充当消息主干，可以跨集群复制消息，并将其永久保存到磁盘以防止数据丢失。

**Cassandra数据模型**

与其他NoSQL数据存储类似，基于Cassandra应用程序的成功数据模型应该遵循“存储你查询的内容”模式。也就是说，与关系数据库相反，在关系数据库中，我们可以以标准化形式存储数据。当我们谈论Cassandra数据模型时，仍然使用术语table，但是Cassandra表的行为更像排序，分布式映射，然后是关系数据库中的表。

Cassandra支持用于定义表与插入和查询数据的SQL语言，称为Cassandra Query Language（CQL）。

当定义一个Cassandra表时，我们需要提供一个分区键，它确定数据在集群节点之间的分布方式，以及确定数据如何排序的聚簇列。当使用CQL查询时，我们只能查询（使用WHERE子句）并根据聚簇列排序。

