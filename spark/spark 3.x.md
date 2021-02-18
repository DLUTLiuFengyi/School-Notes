---
typora-root-url: pic
---

## GPU

### Introduce

https://www.youtube.com/watch?v=4MI_LYah900

<img src="/spark3-1.png" style="zoom:50%;" />

* An explanation of how the Catalyst optimizer physical plan is modified for GPU aware scheduling is reviewed. 

* The talk touches upon how the plugin can take advantage of the RAPIDS specific libraries, cudf, cuio and rmm to run tasks on the GPU. 

* Optimizations were also made to the shuffle plugin to take advantage of the GPU using UCX, a unified communication framework that addresses GPU memory intra and inter node. 

* A roadmap for further optimizations taking advantage of RDMA and GPU Direct Storage are mentioned. Industry standard benchmarks and runs on production datasets will be shared.

```shell
./bin/spark-shell --master yarn --executor-cores 2 \
--conf spark.driver.resource.gpu.amount=1 \
--conf spark.driver.resource.gpu.discoveryScript=/opt/spark/getGpuResources.sh \
--conf spark.executor.resource.gpu.amount=2 \
--conf spark.executor.resource.gpu.discoveryScript=./getGpuResources.sh \
--conf spark.task.resource.gpu.amount=1 \
--files examples/src/main/scripts/getGpuResources.sh
```

用一个脚本去探测一个节点上有多少gpu资源，这个脚本的输出是JSON，JSON会被spark解析并由spark决定如何去使用这个节点上的gpu资源来加速。这个例子使用安装在NVIDIA驱动上的NVIDIA加速库。

```json
{"name":"gpu", "address":["0","1",..."7"]}
```

一旦GPU被探测到，并且spark已经调度了它们，要决定哪一个已经被分配了是很方便的。

例如，我们要请求2个gpu，而每个task正在使用1个gpu，因此要找到一个task已经被分配了哪一个gpu是很有用的。这里有api提供这样的帮助。tasks可以从它们的resources map中获取task context，来获取已经被划分给它们的gpu的地址。

这些地址是String类型，可以被传进TensorFlow或其他ai框架，来决定对某一个特定GPU来说哪一个索引或地址被分配。

类似的，在driver端，可以从sparkContext获取到它被分配的gpu的地址，下面代码中driver没有被分配到gpu。

```scala
//Task api
val context = TaskContext.get()
val resources = context.resources()
val assignedGpuAddrs = resource("gpu").address
// pass assignedGpuAddrs into TensorFlow or other AI code

//Driver api
scala> sc.resources("gpu").address
Array[String] = Array(0)
```

### stage level schedule

SPARK-27495

允许用户给每一个RDD算子确定要分配的资源

* spark dynamically allocates containers to meet resource requirements
* spark schedulers tasks on appropriate containers

## SQL

### SQL Columnar Provessing

SPARK-27396

## Project Hydrogen

<img src="/spark+ai.png" style="zoom:50%;" />

<img src="/spark+ai2.png" style="zoom:50%;" />

SPARK-24374

Unifying state-of-the-art big data and ai in apache spark.

* original Spark: task之间是并行的，一个挂了，其他可以继续执行
* distributed ML framework: task之间彼此存在依赖关系，一个挂了，其他也不能继续执行

**Hydrogen**

* 调度策略与spark有很大不同

* Gang scheduling

  tasks 全有或全无 以协调spark与分布式ml框架之间的基本不兼容性

  所有tasks在一次就调度完，或者没有task被调度

So a distributed DL job can run as a Spark job.

* it starts all tasks together
* it provides sufficient info and tooling to run a hybrid distributed job
* it cancels and restarts all tasks in case of failure

三个stages

* stage1 数据准备

  高度并行

* stage2 分布式ml框架

  gang scheduled

* stage3 data sink

  高度并行

高度并行与gang scheduler之间用barrier来划分

```scala
rdd.barrier().mapPartitions(train)
```

#### demo

```python
#准备拿2个主机进行训练
#这里的分布式训练框架是Horovod，它基于tensorflow之上并将tensorflow与MPI结合起来做分布式训练
model = digits \
    .repartition(2) \ #repar进2个主机
    .toPandasRDD() \ #DataFrame->Pandas using Arrow
    .barrier() \ #在这里加barrier
    #进入下一个stage，we just run Horovod that needs to be gang scheduled
    .mapPartitions(runHorovodEmbedded) \ 
    .collect()[0]
```

#### Optimized data exchange (SPIP)

SPARK-24579

using a standard interface for data exchange to simplify the integrations without introducing much overhead

## Notes

#### 自适应查询执行AQE？

新的AQE框架通过在运行时生成更好的执行计划来提升性能，即使初始的计划不理想（由于缺少或使用了不正确的数据统计信息和错误地估算了成本）。由于 Spark 的数据**存储和计算是分离**的，因此数据的到达是无法预测的。基于这些原因，对于 Spark 来说，运行时自适应比传统系统来得更为重要。新版本引入了三个主要的自适应优化：

- 动态聚结 shuffle 分区可简化甚至是避免调整 shuffle 分区的数量。用户可以在开始时设置相对较大的 shuffle 分区数量，AQE 会在运行时将相邻的小分区合并为较大的分区。
- 动态切换连接策略可以在一定程度上避免由于缺少统计信息或错误估计大小而导致执行次优计划的情况。这种自适应优化可以在运行时自动将排序合并连接（sort-merge join）转换成广播哈希连接（broadcast-hash join），从而进一步提高性能。
- 动态优化倾斜连接（skew join）是另一个关键的性能增强。倾斜连接可能会导致负载的极度失衡并严重降低性能。在 AQE **从 shuffle 文件统计信息中检测到skew join**之后，它可以将倾斜分区拆分为较小的分区，并将它们与另一边的相应分区合并。这个优化可以让倾斜处理并行化，获得更好的整体性能。

join提示：尽管 Databricks 一直在改进编译器，但还是不能保证编译器可以在任何时候做出最佳决策——join算法的选择基于统计信息和启发式。当编译器无法做出最佳选择时，用户可以使用join提示来影响优化器，让它选择更好的执行计划。新版本加入了新的提示：SHUFFLE_MERGE、SHUFFLE_HASH 和 SHUFFLE_REPLICATE_NL。

#### Some tips

##### 提高shuffle性能 2014.11

在提升shuffle方面最近有三个工作对这个比赛影响很大：

* 是sort-based shuffle

  这个功能大大的减少了超大规模作业在shuffle方面的内存占用量，使得我们可以用更多的内存去排序。

* 基于Netty的网络模块取代了原有的NIO网络模块

  这个新的模块提高了网络传输的性能，并且脱离JVM的GC自己管理内存，降低了GC频率。

* 一个独立于Spark executor的external shuffle service

  这样子executor在GC的时候其他节点还可以通过这个service来抓取shuffle数据，所以网络传输本身不受到GC的影响。

##### 中间结果 2014.11

Spark的中间结果绝大多数时候都是从上游的operator直接传递给下游的operator，并不需要通过磁盘。**Shuffle的中间结果会保存在磁盘上**，但是随着我们对shuffle的优化，其实磁盘本身并不是瓶颈。这次参赛也验证了shuffle**真正的瓶颈在于网络，而不是磁盘**。

Tachyon印证了储存系统应该更好利用内存的大趋势。我预测未来越来越多的存储系统会有这方面的考虑和设计，Spark项目的原则就是能够更好的利用下层的储存系统，所以我们也会对这方面做出支持。

值得注意的是，把shuffle数据放入Tachyon或者HDFS cache（HDFS的新功能）其实不是一个好的优化模式。原因是shuffle每个数据块本身非常的小，而**元数据量**非常的多。直接把shuffle数据写入Tachyon或者HDFS这种分布式储存系统多半会直接击垮这些系统的元数据存储，反而导致性能下降。