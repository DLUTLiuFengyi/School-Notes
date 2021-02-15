## Flink

### 流式处理

#### 特点

处理流式数据（像水流一样持续不断）

* 实时聊天

  聊天应该是连续不断产生的，你发一条我接收，我再发一条你接收，你来我往

* 汽车实时定位

* 邮件提醒（产生一条新邮件，就发送信息）

为了计算机实现方便，传统使用批处理（假设数据拿来后，数据源端不产生新数据，攒一批后再处理）

* 低延迟
* 高吞吐
* 准确性和容错性

#### case

* 市场营销

  数据报表，网站点击量（短时间内激增），广告投放（实时反馈），业务流程

* 物联网

  传感器实时数据采集和显示，实时报警，交通运输业

* 电信业

  基站流量调配（某个地区数据量有峰值时，把附近基站调配过来分担压力）

* 银行和金融业

  实时结算和通知推送，实时监测异常行为

  传统做法：一天下午4-5点就下班，然后进行一天数据的整合

#### 分层api

* SQL/Table API

  抽象表

* DataStream API

  数据处理

* ProcessFunction

  事件驱动

  几乎什么都可以做

```shell
#当前并行执行的线程号   所开的线程数与默认核数相同
2> (xxx,1)
```

### 架构

* jobmanager

  管理调度分配任务，类似spark driver，具体任务分配给taskmanager

* taskmanager

  管理自己所负责的task，又叫worker，类似spark的executor，执行具体任务
  
  控制台结果打印到taskmanager的stdout

```properties
#当前task整个进程占用的内存（比下面还多一些堆外内存（不止flink在做状态管理时调度所需内存，还包括jvm本身运行时需要的内存））
taskmanager.memory.process.size
#当前task进程占用的内存（包括堆内堆外，主要指flink在做状态管理时调度所需内存）
taskmanager.memory.flink.size
#一个task可以启动多个slot，slot就是一组分配好的资源，在这个slot上可以执行一个并行流水线，一个任务可以分配到一个slot上执行
taskmanager.numberOfTaskSlots
#并行度
parallelism.default
```

#### Web UI

##### Submit New Job

上传jar包，点击上传后的jar包，添加配置

* 入口类

* main函数参数（host port）

* 可以再指定默认并行度

  并行优先度：代码 -> 提交job时指定 -> 开发环境

  如果并行度小了，则任务就会被压缩，更不容易出现slot不够的情况

* 

只能监控算子内部本身数据，，不能监控外部端口传进来的数据

#### 命令行

```shell
#执行
./bin/flink run -c xxx.xxx(入口类) -p 2(并行度) xxx.jar ...(main参数)
#list
./bin/flink list (-a)
#取消
./bin/flink cancel [JobID] 
```

#### yarn

需要flink-hadoop支持

##### Session-cluster模式

需先启动集群再提交作业，接着向yarn申请一块空间后，资源永远保持不变。如果资源满了，下一个作业无法提交，只能等yarn中一个作业执行完毕后释放的资源。

所有作业共享Dispatcher和ResourceManager，共享资源。

适合规模小执行时间短的作业。

**注意：**在yarn中初始化一个flink集群，开辟指定的资源，以后提交任务都向这里提交。这个flink集群会常驻在yarn集群中，除非手工停止。

##### Per-Job-Cluster模式

一个job会对应一个集群，每提交一个作业会根据自身的情况，都会单独向yarn申请资源，直到作业执行完成。一个作业的失败与否并不会影响下一个作业的正常提交和运行。

独享Dispatcher和ResourceManager，按需接受资源申请。

适合规模大长时间运行的作业。

**注意：**每次提交都会创建一个新的flink集群，任务之间互相独立互不影响，方便管理。任务执行完成后创建的集群也会消失。

### 组件

* JobManager

  接收提交上来的jar包，生成执行计划，把作业分成多个task，分发

* TaskManager

* ResourceManager

  所谓的资源其实就是slot，slot是TM提供的最小化的资源单位（内存划分）

* Dispacher 分发器

#### JobManager

* 控制一个应用程序执行的主进程，每个应用程序都会被一个不同的JM所控制执行
* JM会先接收到要执行的应用程序，这个应用会包括：JobGraph、logical dataflow graph和打包了所有的类库和其他资源的jar包
* JM会把JobGraph转换成一个物理层面的数据流图，这个图被叫做ExecutionGraph，包含了所有可以并发执行的任务
* JM会向资源管理器RM请求执行任务必要的资源，也就是slot，一旦它获取到了足够的资源，就会将ExecutionGraph分发到真正运行它们的TM上。而在运行过程中，JM会负责所有需要中央协调的操作，比如说checkpoints的协调。

#### TaskManager

* Flink中的工作进程。通常在flink中有多个TM运行，每一个都包含多个slots，slots数量限制了TM能执行的任务数
* 启动后，TM会向资源管理器注册它的slots，收到RM的指令后，TM会将一个或多个slots提供给JobManager调用。JM就可以向slots分配tasks来执行。
* 在执行过程中，一个TM可以跟其他运行同一个应用程序的TM交换数据。

集群静态并行计算能力 = slots总数 = TM数量*每个TM含slots数量

（要与并行度区分）

#### Dispatcher

* 可跨作业运行，为应用提交提供了rest接口
* 当一个应用被提交执行时，分发器就会启动并将应用移交给一个JobManager
* Dispatcher也会启动web ui
* 在架构中不是必需

#### 任务调度

原始代码 ->客户端解析成 logical graph -> 客户端（UI、命令行）发送给JM

客户端对graph进行调整，可以合并的操作进行合并

graph合并后得到新的graph: job graph

graph和jar包等提交给JM

JM进行分析，判断当前并行度，每个任务有几个并行子任务，需要多少slot，分配

JM向RM申请资源，RM向TM提出slot资源注册请求

TM的slots资源可以不完全用完，这与当前并行度（所需slots）有关

执行过程中，JM会发出一些指令（分发、停止、取消）给TM，也会发出checkpoint指令

**思考**

并行的任务需要占用多少slot？

当前任务的子任务都分别分配到一个slot，一个slot执行一个task

一个流处理程序，到底包含多少个任务？

任务可能会合并

wordcount，6个任务，并行度为2，跑不起来；若是改成并行度为1，2个任务，只有1个slot，也能跑起来。

##### 并行度

一个特定算子的子任务（subtask）的个数被称为并行度（parallelism）。

各算子并行度之和等于总任务数

一般一个stream的并行度可以认为是所有算子中最大的并行度

##### Slot

按照flink内存去划分

**技巧：**目前flink的slot对cpu没有隔离

TM直接把内存化成三等份，即是三个slot

Flink每一个TM都是一个jvm进程，里面进行的每一个任务即是一个独立的线程，线程所占据的资源即是slot

默认情况下，flink运行子任务共享slot（允许把先后发生的不同任务放在一个slot中），**即使它们是不同任务的子任务** ，这样的结果是一个slot可以保存作业的整个**管道**（整个处理流程的每一步操作，好处是可以在本地执行完毕，不涉及数据的来回传输shuffle，而且容错）（也避免忙的slot一直忙闲的slot一直闲的情况发生，闲的slot(source算子)可以分担忙的slot(windows算子)的任务）

task slot是静态概念，是指TM具有的并发执行能力 

例如，总任务数是1+2+2+1=6，需要6个slot，而其实只需要2个slot即可

因此最少所需slot数等于最大并行度（并行度最高的算子的并行度）

### DataFlow

哪些任务能合并哪些不能合并？

所有flink程序都由三部分组成

* source

  读数据源

* transformation

  处理加工

* sink

  输出

dataflow类似DAG，一个或多个source，一个或多个sink

不会划分stage，而是直接画出DAG，大部分情况下transformation跟dataflow中的算子是一一对应的。一切都是流，不会划分stage

#### ExecutionGraph

* StreamGraph

  调用流处理api直接生成的图

  client上生成

* JobGraph

  合并

  client上生成

* ExecutionGraph

   根据并行度把每一个任务拆开，数据从哪个子任务来、发送给哪个子任务

  JM上生成

* 物理执行图

  task上执行

#### 数据传输

算子间传输数据形式可能是one-to-one，也可能是redistributing

* one-to-one

  下一个算子的子任务看到的元素的个数以及和顺序跟上一个算子的子任务生产的元素的个数、顺序相同

* redistributing

  stream的分区会发生改变。每一个算子的子任务依据所选择的transformation发送数据到不同的目标任务。

  例如keyby基于hashcode重分区、而broadcast和rebalance会重新分区，这些算子都会引起redistribute过程，而redistribute过程就类似于spark中的shuffle过程。

  上下游并行度不同也会产生redistribution，策略：**轮询**地发送到下游每一个并行子任务

#### 任务链

优化技术，可以减少本地通信开销

执行条件

* 并行度相同
* one-to-one

通过本地转发（local forward）的方式进行连接

相同并行度的one-to-one操作，这样相连的算子连接在一起形成一个task，原来的算子成为里面的subtask

##### 解除任务链

在某一步操作中有一个很复杂的算子，需要将其从任务链中拆出来，单独分配大并行度

```scala
.filter(...).disableChaining()//filter前后都断开 
```

从某个算子开始，算子前是一条chain，算子及算子后是另一条chain

```scaal
.map(...).startNewChain()
```

让某些任务独享自己的slot

```scala
.flatMap(...).slotSharingGroup("a")//在a组里的算子都分配在一个slot中，其他组的算子一定不在这个slot
```

**技巧：**组的分配怎么分配？

默认所有算子都在一个组里

关闭任务链

```scala
env.disableOperatorChaining()
```

### 执行环境

表示当前执行程序的上下文

```scala
getExecutionEnvironment//会自动判断返回的是本地还是集群的环境
```

```scala
//本地环境，需要设置并行度
StreamExe...Env.createLocalEnvironment(1)
//集群环境，并行度根据flink-conf.yaml中配置确定
Exe...Env.createRemoteEnvironment("jobmanager-hostname",6123,".../xxx.jar")
```

### API

#### 数据类型

数据对象需要被序列化和反序列化，网络传输，或从状态后端、检查点和保存点读取它们。

Flink支持java和scala中所有常见数据类型

#### UDF

Flink暴露了所有udf函数的接口（实现方式为接口或者抽象类），如MapFunction，FilterFunction，ProcessFunction

```scala
class MyFilterFunction extends FilterFunction[String]
```

#### RichFunction

富函数可以获取到运行时上下文和生命周期

#### sink

flink底层不像spark那样有RDD，能使用foreach迭代来对外输出，因此只能sink，而flink需要考虑分布式系统的正确性（某些节点停了该怎么做）

因此建议用标准sink

* Kafka
* Cassandra
* Elasticsearch
* HDFS
* RabbitMQ

Apache Bahir：为flink、spark等提供连接支持的包

* Flume
* Redis
* Akka
* Netty