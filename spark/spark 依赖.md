窄依赖

* 1个父RDD对应1个子RDD   

  map, filter, union

* N个父RDD对应1个子RDD   

  co-partitioned join

宽依赖

* 1个父RDD对应N个子RDD   

  groupByKey, reduceByKey, sortByKey, 未经协同划分join

**窄依赖**

可以支持在同一个集群Executor上，以pipeline管道形式顺序执行多条命令

分区内的计算收敛，不需要依赖所有分区的数据，**可以并行地在不同节点进行计算**

所以它的失败回复也更有效，因为它只需要重新计算丢失的parent partition即可

**宽依赖**

又叫shuffle依赖

则需要所有的父分区都是可用的，必须等RDD的parent partition数据全部ready之后才能开始计算，可能还需要调用类似MapReduce之类的操作进行跨节点传递。

#### stage划分

根据宽依赖划分

由于shuffle依赖必须等RDD的父RDD分区数据全部可读之后才能开始计算，因此Spark的设计是让父RDD将结果写在本地，完全写完之后，通知后面的RDD。后面的RDD则首先去读之前RDD的本地数据作为输入，然后进行运算。

**Each stage is a set of tasks that run in parallel.**

1. 从后往前推理，遇到宽依赖就断开，遇到窄依赖就把当前RDD加入到该Stage

2. 每个Stage里面Task的数量是由该Stage中最后一个RDD的Partition的数量所决定的。

3. 最后一个Stage里面的任务类型是ResultTask，前面其他所有的Stage的任务类型是ShuffleMapTask。

4. 代表当前Stage的算子一定是该Stage的最后一个计算步骤

**表面上看是数据在流动，实质上是算子在流动。**

- 数据不动代码动
- 在一个Stage内部算子为何会流动（Pipeline）？
  - 首先是**算子合并**，也就是所谓的函数式编程的执行的时候最终进行函数的展开从而把一个Stage内部的多个算子合并成为一个大算子（其内部包含了当前Stage中所有算子对数据的计算逻辑）；
  - 其次，是由于Transformation操作的Lazy特性！在具体算子交给集群的Executor计算之前首先会通过Spark Framework(DAGScheduler)进行**算子的优化**（基于数据本地性的Pipeline）。