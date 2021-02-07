#### RAPIDS

基于CUDA的开源GPU加速库

数据准备 -> 模型预测   端到端

原生支持 cuDF, cuML, cuGraph

与Tensorflow等DL框架合起来支持 cuDL

处理的数据以Apache Arrow格式存储在GPU内存中

批处理方面主要针对提供Spark SQL的GPU加速

#### ACSP

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

##### 适用场景

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

##### 阿里云自研RAPIDS Spark Operator

在kubernetes上

**EMR** 

单独收费产品 需要深度定制 尚不支持RDMA

---

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

---

#### BigDL

intel开源，基于spark的深度学习框架

特点：

* CPU
* 纯分布式（Spark）

作者：AlfredXXfiTTs
链接：https://www.zhihu.com/question/54604301/answer/338630738

* 比如，现有Hadoop集群的公司，复用现有集群来跑深度学习是最经济的方案。

* 并且，充分优化后的CPU集群的性能还是挺可观的。

  拿BigDL来说，MKL + 多线程 + Spark，充分发挥了分布式集群的优势 。尤其是在Inference方面，堆CPU的方案在性价比上很可能是优于GPU的，毕竟Nivdia的计算卡是很昂贵的。

* 另外，数据挖掘以及Information Retrieval等领域中常用的神经网络结构一般都比较浅，多为稀疏网络，也很少用到卷积层。GPU并不十分擅长处理这样的网络结构。

* 实际的生产环境，跑在Spark上的BigDL背后有整个Spark/Hadoop大生态的支持。配合近期很火的SMACK技术栈，可以很轻松愉快的构建端到端的生产级别的分布式机器学习流水线。由于没有异构集群数据传输的开销，从端到端这个层面来看，CPU方案的性能反而可能占优。

* 最后，可用性，BigDL项目正在快速的迭代中。

  * 语言层面支持Scala/Python

  * API方面有torch.nn风格的Sequenial API，也有TensorFlow风格的Graph API，以及正在开发的keras API

  * Layer库也很齐全，自定义Layer也很方便

  * 兼容性方面，BigDL兼容了Caffe/Torch/Keras，以及部分TensorFlow模型。换言之，你可以把用TF/Caffe训练的模型，导入BigDL做Inference。反之，亦可。这是一个非常有用的Feature。

综上，BigDL虽然并不主流，但在很多场景下是有成为"大杀器"潜质的，包括但不限于：

1. 已有大规模分布式集群的(如: Hadoop集群)
2. 需要大规模Inference的，比如：推荐系统、搜索系统、广告系统
3. (上下游)依赖Spark/Hadoop生态的
4. 轻度深度学习使用者，如：数据研发工程师/数据挖掘工程师
5. Scala/JVM爱好者

**Paper**

https://bigdl-project.github.io/0.5.0/#whitepaper/