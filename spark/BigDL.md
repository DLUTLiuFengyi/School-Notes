### BigDL

intel开源，基于spark的深度学习框架

#### 特点

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

#### White Paper

https://bigdl-project.github.io/0.5.0/#whitepaper/

#### Ideas

The *shuffle* and *task-side broadcast* operations described above are implemented on top of the distributed **in-memory** storage in Spark: both the shuffled *gradients* and broadcasted *weights* are materialized in memory, which can be read remotely by the Spark tasks with extremely low latency.

是否可以用零拷贝技术优化？