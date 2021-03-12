---
typora-root-url: pic
---

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

任务调度、资源分配等图

http://blog.itpub.net/69982513/viewspace-2714497/

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

### 时间语义和watermark

<img src="/time1.png" style="zoom:60%;" />

往往更关心event time

可以在代码中对env调用`setStreamTimeCharacteristic`设置流的时间特性

```scala
val env = ...
env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)
```

flink以event time模式处理数据时，会根据数据里的时间戳来处理基于时间的算子

由于网络、分布式等原因，会导致乱序数据的产生

**思考** 时间窗口延迟要等多久？

根据时间戳+event time来判断，带着9点02分时间戳的数据来了，则认为现在时间到9点02分了，而系统现在到几点了并不重要

根据接收到数据的时间戳变大来更新当前时间。例如窗口长度为5秒，则时间戳为5的数据到来了，则可以关闭窗口

#### Watermark

注意，下面讨论的时间戳是用来决定何时关闭窗口（桶）的

##### 乱序数据

引入一个整体的时间判断机制，让时间稍微滞后。

如5秒的时间戳来了后，还不能认为已进行到5秒

延迟触发

正确处理乱序数据：watermark结合window

数据流中的watermark用于表示时间戳小于watermark的数据，都已经到达了，因此windows的执行也是由watermark触发的

lambda架构：先用实时流处理系统输出近似结果，再等数据都到了之后，用批处理输出准确结果。**而watermark就将流处理与批处理的选择交给程序去权衡**，wm越小，实时性越好、延迟性越小，wm设成0就相当于来了什么数据，就按当前这个数据的时间戳确定时间

wm直接插入到流中，相当于一条特殊的数据记录，必须单调递增

**取值** 取当前所有已经到达数据的时间戳的最大值再减去一个固定的值

窗口是左闭右开的

延迟 = 乱序程度的最大值

##### 分布式

如果上下游有多个并行子任务：

* 上游往下游传时，直接广播
* 下游接收上游的wm时，会维护一个分区wm，自己的时钟以最慢的wm决定

上游有并行任务1 2 3，假设wm是4，此时上游的1不再有4之前的数据发送给下游，但2 3有可能还要4之前的数据

<img src="/wm.png" style="zoom:67%;" />

**解决** 在下游任务里给上游的每一个并行子任务设置一个分区watermark。那该按哪一个分区wm来定？以最慢的wm（最小的分区时钟）来定。

```scala
//从当前数据中提取时间戳并指定wm的生成方式
//timestamp与wm通常是一起的
val dataStream = ...
  //.assignTimestampsAndWatermarks
  .assignAccendingTimestamps(_.timestamp * 1000L) //保证是毫秒级时间戳
```

* 周期性

  数据密集 短时间内大量数据涌入 大数据常见场景

* 间断性（来一个数据生成一个wm）

  数据稀疏

#### 窗口起点的确定

```java
TumblingProcessingTimeWindows.java
//确定窗口从哪开始
public Collection<TimeWindow> assignWindows
TimeWindow.java
//确定窗口从哪开始，输出是window起始位置
public static long getWindowStartWithOffset(timestamp,offset,windowSize) {
    return timestamp-(timestamp-offset+windowSize)%windowSize
    //假设时间戳是199
    // 199-(199-0+15)%15=195
    // 则第一个窗口是[195-210)
}
```

### 状态管理

* operator state

* keyed state

* state backend

先清楚flink定位：分布式计算框架，对有状态数据流进行计算

<img src="/state1.png" style="zoom:67%;" />

flink中的状态：

* 由一个任务维护、并用来计算某个结果的所有数据，都属于这个任务的**状态**
* 可认为状态就是一个**本地变量**，可被任务的业务逻辑访问
* flink会进行状态管理，包括状态一致性、故障处理以及高效存储和访问，以便开发人员专注于应用程序的逻辑

简单的transform操作，只跟当前数据有关，并不需要状态。而reduce、windows、min、sum操作，就需要状态（依赖于之前所有数据的统计）

每一个state必须跟特定的算子相关联

为了使运行时的flink了解算子状态，算子需要预先在运行环境中**注册**其状态

* operator state

  作用范围（变量的作用域）限定为算子任务

  假设有3个并行的子任务，则每一个并行子任务中都有一块内存去存状态，而互相无法访问（除非是特殊的广播状态），因此算子状态作用访问是当前任务中的一部分即当前同一个分区（3个中的1个）

* keyed state

  根据输入数据流中定义的key来维护和访问

  在同一个分区中按照不同的key会将内存继续划分成不同部分，不同的key访问不同的状态（内存分区）

#### 算子状态

由同一并行任务所处理的所有数据都可以访问到相同的状态

不能由相同或不同算子的另一个子任务访问

数据结构

* list state

  将状态表示为一组数据的列表

  * 并行度调整 2->3

    把list拆开

  * 故障恢复

    保存的时候拼起来，最后恢复时再打散

* union list state

  将状态表示为一组数据的列表，与常规list state区别在发生故障或者从保存点启动app时如何恢复

  * 故障恢复

    把之前每一个并行子任务的算子状态都保存了一份，然后把状态作动态调整

* broadcast state

  如果一个算子有多个任务，而每项任务状态都相同，则这种情况适用于广播状态

#### 键控状态

<img src="/state2.png" style="zoom:67%;" />

根据输入流中定义的key来维护和访问

flink为每一个key维护一个state实例，并将具有相同建的所有数据都分区到同一个算子任务中，这个任务会维护和处理这个key对应的状态

当一个任务处理一条数据时，它会自动将状态的访问范围限定为当前数据的key

数据结构

* value state

  状态表示为单个值

* list state

* map state

  状态表示为一组键值对

* reducing state / aggregating sate

  状态表示为一个用于聚合操作的列表
  
  reduce, sum, min, max底层就是聚合状态

```scala
//声明一个key state
lazy val lastTemp: ValueState[Double] = getRuntimeContext.getState[Double] {
    //state的描述器
    //当前状态名称 当前状态类型
    new ValueStateDescriptor[Double]("lastTemp",classOf[Double])
}
//rich function可以获取到运行时上下文以及生命周期等方法

//读取state
val prevTemp = lastTemp.value()

//对state赋值
lastTemp.update(value.temperature)
```

#### 状态后端

每个并行任务都会在本地维护其状态，以确保快速的状态访问

状态的存储、访问、维护由一个可插入的组件决定，这个组件叫**状态后端**state backend

状态后端负责

* 本地状态管理
* 将checkpoint状态写入远程存储

**分类**

##### MemoryStateBackend

内存级，将键控状态作为内存中对象进行管理，将它们存储在TaskManager的jvm堆上，将checkpoint存储在JobManager的内存中

快速、低延迟，但不稳定

生成环境不用，用于测试环境

##### FsStateBackend

将checkpoint存到远程的持久化文件系统中，将本地状态跟MemorySB一样存在TaskManager的jvm堆上

内存级本地访问速度，更好容错

集群启动时默认选择此模式

```scala
env.setStateBackend(new FsStateBackend(...)) //参数是文件路径，可以是HDFS
```

##### RocksDBStateBackend

将**所有**状态序列化后存入本地的RocksDB中存储

内嵌的kv数据库，读写快，也可以落盘，不受到内存容量限制，但访问性能受到影响

状态多的时候选择此模式

```scala
env.setStateBackend(new RocksDBStateBackend(...)) //参数是uri
//可选的参数 增量化checkpoint（基于上一次存盘的checkpoint）
```

### 容错机制

状态不丢，接下来在之前基础上把数据重新读进来

* checkpoint

  自动存盘

* cp算法

* save points

  手动存盘

#### 一致性检查点checkpoint

在某个时间点把所有状态保存起来，等到出现故障、要恢复了，再把状态挨个读出来

这个时间点应该是所有任务都恰好处理完一个相同的输入数据的时候

<img src="/rongcuo1.png" style="zoom:50%;" />

```txt
奇偶分别求和，当前读取的偏移量是0-5（offset也要保存）
如果是
4+2=6
3+1=4
则会产生offset冲突
所以要奇偶都处理完了再保存offset，也就是保存checkpoint
```

<img src="/cp1.png" style="zoom:50%;" />

<img src="/cp2.png" style="zoom:50%;" />

重启后是空状态，然后是加载最近一次保存的checkpoint

<img src="/cp3.png" style="zoom:50%;" />

注意这里的偶数和12变回了6

<img src="/cp4.png" style="zoom:50%;" />

#### 实现算法

如何判断当前任务真的都完成了？

上下文（当前处理到了哪里），stop-the-world，暂停应用？

flink的改进

* 基于 **Chandy-Lamport **算法的分布式快照
* 将checkpoint的保存和数据处理分开，不暂停整个应用

引入一个针对数据的标记机制（在数据流中加入一个标记）

某某学完后，那个人就下楼拍照，最后把所有人分别拍好的照拼起来

##### 检查点分界线 checkpoint barrier

用来将一条流上数据按照不同的检查点分开。

* 分界线之前到来的数据导致的状态更改，都会被包含在当前分界线所属的检查点中
* 基于分界线之后的数据导致的所有更改，就会被包含在之后的检查点中

JM向source发起指令：TM注意了，要进行cp操作

让source往数据中插入barrier

因为数据是从source中流出的

**又有问题**

刚刚没涉及到多个并行子任务的讨论

广播？下游任务还会接收到不同上游的barrier

wm等所有分区wm都达到某一个最小值

b也是需要收集上游所有barrier，再选最小的

<img src="/cp5.png" style="zoom:50%;" />

下面的2代表1+1，5代表2+黄3，而蓝3还没有到达加法部分，所以此时该流有多种情况

<img src="/cp6.png" style="zoom:50%;" />

上图中，两个source任务收到指令，因此插入barrier 2

注意上图中最右边的任务并没有闲着，蓝2和黄2都已经写入到sink流中

然后source任务先对自己当前状态进行保存（蓝3黄4），落盘

<img src="/cp7.png" style="zoom:50%;" />

保存完状态蓝3黄4后，会给JM返回一个信息，JM知道source已经搞定，然后source任务会把自己插入的barrier向下游广播。这一段时间内source任务都不能读取数据，但右边的任务也没有闲着（谁做保存谁暂停，其他人不暂停）。

保存的状态是蓝3黄4，而蓝3已经到下面分支并与5相加成蓝8了，而黄4还没到，因此sum even任务必须等两个流的barrier都到齐才能保存状态（barrier对齐）

**注意** 对上面的分支中的sum even，如果蓝色barrier（蓝2）已经来了，即使后面蓝色数据（蓝4）来了，也必须先缓存着，不进行计算，即使现在空闲，也需要先把状态蓝3黄4处理完

<img src="/cp8.png" style="zoom:50%;" />

而黄4进到sum even任务了，则sum even执行，4+4=8

<img src="/cp9.png" style="zoom:50%;" />

sum even的状态是8（2+2+4），sum odd的状态是8（5+3）

sum even左上角的蓝4是先缓存、尚未处理的数据，因此处理

下游的sink1 sink2收到barrier（三角形2）之后，也会进行自己状态的保存

<img src="/cp10.png" style="zoom:50%;" />

所有任务都处理完成后，都通知JM，然后JM知道现在所有状态都保存成功

<img src="/cp11.png" style="zoom:50%;" />

当前的checkpoint正式完成

#### 保存点savepoint

可以自定义的镜像保存功能

保存点可以认为是具有一些额外元数据的检查点

* 故障恢复
* 手动备份
* 更新app
* 版本迁移
* 暂停和重启app

### 状态一致性

有状态的流处理，内部每个算子任务都可以有自己的状态

结果要保证准确，一条数据不应该丢失，也不应该重复计算，故障恢复后重新计算的结果应该也是完全正确的

#### 端到端 exactly-once

* 内部保证 checkpoint
* source端 可重设数据的读取位置
* sink端 从故障恢复时，数据不会重复写入外部系统
  * 幂等写入

  * 事务写入

    原子性

    构建的事务跟checkpoint一一对应，等到cp真正完成的时候，才把所有对应的结果写入sink系统中（cp完成时，就是数据操作内部状态都已完成且外部sink已启动、后边数据一个都没操作一个都没更改）

    实现方式

    * 预写日志

      把要sink的数据都当成状态保存，跟checkpoint捆绑

      缺点是类似批处理，一次性写入

    * **两阶段提交**

      * 对每个cp，sink任务都启动一个事务，并将接下来所有接收的数据添加到事务中

      * 然后将这些数据写入外部sink，但不提交它们，此时只是 **预提交**

      * 当它收到cp完成通知时，它才正式提交事务，实现结果的真正写入

      这种方式真正实现了exactly-once，它需要一个提供事务支持的外部sink系统

      TwoPhaseCommitSinkFunction

      跟预写日志区别是后者类似批处理思想，前者还是流处理来一个算一个，只不过在sink端用事务的角度来处理，可以撤销事务，这里事务类似checkpoint，遇到barrier就正式关闭事务并提交数据

      缺点：

      * 外部sink系统必须能提供事务支持

      * 在收到scheckpoint完成的通知（barrier）之前，事务必须是“等待提交”状态，在故障恢复情况下，这可能需要一些时间

        如果此时sink关闭事务（如超时），则未提交的数据就会丢失

      * sink任务必须能够在进程失败后恢复事务

      * 提交事务必须是幂等操作

隔离级别：read committed

**Exactly-once 两阶段提交**

* 第一条数据来了后，开启一个kafka事务，正常写入kafka分区日志但标记为未提交，这就是“预提交”
* jobmanager触发checkpoint操作，barrier从source开始向下传递，遇到barrier的算子将状态存入状态后端，并通知jobmanager
* sink连接器接收到barrier，保存当前状态，存入checkpoint，通知JM，并开启下一阶段的事务，用于提交下个checkpoint的数据
* JM收到所有任务的通知，发出确认信息，表示checkpoint完成
* sink任务收到JM的确认信息，正式提交这段时间的数据
* 外部kafka关闭事务，提交的数据可以正常消费了

<img src="/api.png" style="zoom:60%;" />

flink1.9开始，阿里开源，有了统一标准

<img src="/api2.png" style="zoom:50%;" />

<img src="/api3.png" style="zoom:50%;" />