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