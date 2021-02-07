### 相关组件

#### Driver和Executor

**计算相关组件**

executor有2个核心功能

* 运行组成spark应用的任务，并将结果返回给驱动器进程

* 通过自身的Block Manager为用户程序中要求缓存的RDD提供 **内存式存储** 

  RDD是直接缓存在exeutor进程中的，因此任务可以在运行时充分利用缓存数据加速运算

Executor是集群运行在工作节点（worker）中的一个jvm进程，是集群中专门计算的节点，主要执行task

#### Master和Worker

**资源相关组件**

只在standalone模式存在这两个概念，因为需要spark自己提供资源管理和资源调度。

类似对比于yarn中的ResourceManager和NodeManager

master：一个进程，主要负责资源调度和分配，并进行集群的监控等

worker：也是进程，一个worker运行在集群中的一台主机上，由master分配资源对数据进行并行处理和计算

#### ApplicationMaster

如果计算和资源（Driver和Master）直接进行交互，则会增加耦合度

因此让D和M并不能直接交互

在二者间放一个ApplicationMaster

D委托AM，AM再向M申请资源



### 计算流程

在driver端把用户传给的计算逻辑、计算数据封装好，然后传给executor，后者只是干活的。



### RDD

RDD中有数据和逻辑，相当于视频举例中的"Task"，而driver发送给executor的是"SubTask"，即RDD会被分解成多个task，发给不同的executor执行

```txt
RDD
1,2,3,4
num * 2

Task
1,2
num * 2

Task
3,4
num * 2
```

**java I/O 缓冲机制**

一个一个读（字节流）

```java
// 仅仅比非缓冲机制多一层函数new BufferedInputStream()
InputStream in = new BufferedInputStream(new FileInputStream("path"));
int i = -1;
while ((i = in.read()) != -1) {
    println(i);
}
```

缓冲机制是批处理思想的来源之一

一行一行读（字符流）

```java
// 需要一个转换流在中间把字节转换成字符，因此加一层new InputStreamReader()
Reader in = new BufferedReader(new InputStreamReader(new FileInputStream("path"), "UTF-8"));
String s = null;
while ((s = in.readLine()) != null) {
    println(i);
}
```

utf-8是字符编码，英文字母一个字节是一个字符，亚洲文字两个字节是一个字符，utf-8三个字节是一个字符

以上是装饰者设计模式：核心不变，在原来的基础上扩展更为丰富的功能

I/O操作体现了装饰者模式

ABC -> StreamReader的缓冲区（ABC一个一个传进来） -> 缓冲区（缓冲区达到阈值，ABC转换成一个汉字“中”） -> BufferedReader的缓冲区（汉字“中国”一个个传过来） -> 缓冲区达到阈值即readline -> 打印出来



flatmap会new一个新的mappartitionRDD并把原RDD传进去，对其进行包装

```scala
val rdd : RDD = new HadoopRDD() - textFile // 这里拿到的是一行一行的数据"Hello Scala""Hello Spark"
val rdd1 : RDD = new MapPartitionRDD(rdd) - flatMap // "Hello""Scala"Hello""Spark"
val rdd2 : RDD = new MapPartitionRDD(rdd1) - map // (Hello,1)(Scala,1)(Hello,1)(Spark,1)
val rdd3 : RDD = new ShuffleRDD(rdd2) - reduceByKey // (Hello,1)(Hello,1)(Scala,1)(Spark,1)
												// (Hello,2)(Scala,1)(Spark,1)
-> collect
```

调用collect才执行，之前都是扩展，RDD中间不存储任何数据，数据是原封不断往下流转

RDD不保存数据，但I/O可以临时保存一部分数据（RDD与I/O的差别）

一个RDD是最小计算单元，里面不能有太复杂的逻辑，如果要实现复杂功能，则需要组合多个RDD

* 弹性
  * 自动选择存储在内存还是磁盘
  * 数据丢失可重新计算：(3,4)可以重新读
  * 计算出错可重新读
  * 可用executor增加，则task数量（分区数）也可以随之增多

* RDD封装了计算逻辑，并不保存数据

  指的是"Hello Scala"变成"Hello" "Scala"后，HadoopRDD内部就不存在数据了

* 不可变：RDD封装了计算逻辑，一旦封装好后，逻辑是不可以发生改变的，只能新建RDD来改变RDD

#### RDD核心属性

**1. 分区列表**

为了实现并行计算

Array[Partition]

**2. 分区计算函数**

每个分区有一个计算函数

def compute(): Iterator[T] 

**3. 依赖关系**

多个RDD之间形成的依赖关系

ShuffleRDD一路依赖到HadoopRDD

**4. 分区器**

靠规则（即分区器）来确定数据如何分区

val partition: Option[Partitioner] = null

option表示有或没有，scala中为了解决空指针异常

**5. 首选位置**

判断task（计算）发送到哪一个节点的效率是最优的

把task发给有数据（word.txt）的executor，来尽量减少网络I/O

**移动数据不如移动计算**