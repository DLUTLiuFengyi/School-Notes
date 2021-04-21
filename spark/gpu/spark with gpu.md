---
typora-root-url: pic
---

### RAPIDS

基于CUDA的开源GPU加速库

数据准备 -> 模型预测   端到端

原生支持 cuDF, cuML, cuGraph

与Tensorflow等DL框架合起来支持 cuDL

处理的数据以Apache Arrow格式存储在GPU内存中

批处理方面主要针对提供Spark SQL的GPU加速

#### Accelerating Apache Spark 3.0 with GPUs and RAPIDS

<img src="/rapids1.png" style="zoom:50%;" />

##### Data Structure

a powerful GPU DataFrame based on [Apache Arrow](http://arrow.apache.org/) data structures

columnar memory format, optimized for data locality, to accelerate analytical processing performance on modern CPUs or GPUs

With the GPU DataFrame, batches of column values from multiple records take advantage of modern GPU designs and accelerate reading, queries, and writing.

With a physical plan for CPUs, the DataFrame data is transformed into RDD row format and usually processed one row at a time. Spark supports columnar batch, but in Spark 2.x only the Vectorized Parquet and ORC readers use it. The RAPIDS plugin extends columnar batch processing on GPUs to most Spark operations.

##### Shuffles Accelerate - UCX

<img src="/rapids2.png" style="zoom:50%;" />

The new Spark shuffle implementation is built upon the GPU-accelerated [Unified Communication X (UCX)](https://www.openucx.org/) library to dramatically optimize the data transfer between Spark processes. 

UCX exposes a set of abstract communication primitives which utilize the best of available hardware resources and offloads:

* RDMA
* TCP
* GPUs
* shared memory
* and network atomic operations

In the new shuffle process, as much data as possible is first **cached on the GPU**. This means no shuffling of data for the next task on that GPU. 

Next

* If GPUs are on the same node and connected with NVIDIA NVLink high-speed interconnect, data is transferred at 300 GB/s. 

* If GPUs are on different nodes, **RDMA** allows GPUs to communicate directly with each other, across nodes, at up to 100 Gb/s. Each of these cases avoids traffic on the PCI-e bus and CPU. （应该算是零拷贝）

<img src="/rapids3.png" style="zoom:50%;" />

If the shuffle data cannot all be cached locally:

* it is first pushed to host memory 
* and then spilled to disk when that is exhausted

**Fetching data from host memory avoids PCI bus traffic by using RDMA** transfer. 

<img src="/rapids4.png" style="zoom:50%;" />

##### GPU-aware scheduling in Spark

This allows Spark 3.0 can schedule executors with a specified number of GPUs, and you can specify **how many GPUs each task requires**. 

Spark conveys these resource requests to the underlying cluster manager, Kubernetes, YARN, or standalone. You can also configure a discovery script to detect which GPUs were assigned by the cluster manager. 

<img src="/rapids5.png" style="zoom:75%;" />

Figure 14 shows an example of a flow for GPU scheduling. 

* The user submits an application with a GPU resource configuration discovery script. 
* Spark starts the driver, which uses the configuration to pass on to the cluster manager, **to request a container with a specified amount of resources and GPUs**(spark源码解析)
* The cluster manager returns the container(还是跟源码解析里一样). 
* Spark launches the container(源码again). 
* When the executor starts, it runs the discovery script. 
* Spark sends that information back to the driver and the driver can then use that information to schedule tasks to GPUs.

**笔记：** 

* 其实还是没说具体根据什么调度？把GPU地址或GPU内部单元的地址交给tensorflow等ai框架让它们来调度使用GPU？
* 现在GPU加速的Spark ML只实现了XGBoost





### ACSP

阿里云在Spark RAPIDS plug-in基础上进行的优化

* 参数优化（减少参数，spark参数自动调优）
  * 静态调优（根据规则）
  * 动态调优（3.0 GPU AQE 数据运算时动态调优）
* 算子优化（自适应优化）
  * RBO规则（自动寻找性能最优的算子组合）
* spark shuffle优化
  * 拓扑优化（自动识别拓扑并寻找最优数据路径，保证shuffle过程中数据传输的高效）

数据集：TPCx-BB 模拟零售商30个应用场景

测试CPU与GPU优化的性能比较（性能 + 价格 -> 性价比）

#### 适用场景

传统spark应用场景即可

cpu -> gpu无缝切换

影响GPU加速SQL性能的因素

* 数据规模小

  GPU每个分区仅处理几百兆的数据，浪费

* 数据搬移

  慢速I/O设备

  与CPU交互

  shuffle

* GPU显存有限

GPU擅长的SQL运算

* 高散列度数据的join、agg、sort

* Window operation（尤其是大window）

* 复杂计算

* 数据编码（创建Parquet和ORC文件, 读取csv）

#### 阿里云自研RAPIDS Spark Operator

在kubernetes上

**EMR** 

单独收费产品 需要深度定制 尚不支持RDMA

---

### 某博客

https://blog.csdn.net/jiede1/article/details/85214278

目的：为了使用spark进行机器学习，支持GPU是必须的，上层再运行神经网络引擎。

因为Spark是多线程的，而GPU往往只能起一个单例，导致线程会竞争GPU资源，需要进行管理、加锁和调度。这包括几个层次：

- 原生代码内置编译支持。
- 引入cuDNN等NVidia库进行调用。
- 通过Tensorflow等间接进行支持。
- JIT方式即时编译调用方式支持。
- GPU支持的Docker中运行Spark。如果将Spark节点放入Docker容器中运行，则需要使用NVidia提供的特殊版本Docker，而且需要安装NVidai提供的cuDNN等软件支持库。由于这些库调用了系统驱动，而且是C++编写，因此Spark要能够进行系统库的调用。
- GPU支持的Kubernetes之上运行Spark。在上面的基础上，支持GPU的Docker容器需要能够接受Kubernetes的管理和调度。参考：https://my.oschina.net/u/2306127/blog/1808304

只有同时满足上面的条件，才能通过Kubernetes的集群管理对Docker中Spark进行GPU操作。下面是已经做的一些研究。

- IBMSparkGPU的方案可以将GPU用于RDD和DataFrame，支持通用计算，重点支持机器学习；

- deeplearning4j是基于Java的，包含数值计算和神经网络，支持GPU；

- NUMBA的方案通过PySpark即时编译产生GPU的调用代码，兼容性好；

- Tensorflow/Caffe/MXNet等与Spark整合主要是节点调度，GPU由深度学习引擎调度，RDD需要数据交换，主要用于存储中间超参数数据。

  如TensorFrame的实现https://github.com/databricks/tensorframes
