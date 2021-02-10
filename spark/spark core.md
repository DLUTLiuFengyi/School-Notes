---
typora-root-url: pic
---

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

Spark三大数据结构

* RDD：弹性分布式数据集
* 累加器：分布式共享只写变量
* 广播变量：分布式共享只读变量

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

所以RDD都有一个分区列表，记录每个数据在哪个分区

**2. 分区计算函数**

每个分区有一个计算函数

def compute(): Iterator[T] 

**3. 依赖关系**

多个RDD之间形成的依赖关系

ShuffleRDD一路依赖到HadoopRDD

**4. 分区器**

靠规则（即分区器）来确定数据如何分区

val partition: Option[Partitioner] = null

option表示partition属性有或没有，scala中为了解决空指针异常的语法

**5. 首选位置**

判断task（计算）发送到哪一个节点的效率是最优的

把task发给有数据（word.txt）的executor，来尽量减少网络I/O

**移动数据不如移动计算**



**注意：**分区和并行度不一定相同，比如当只有1个executor时，就算task有多个，也只能在这1个executor中并发执行



默认并行度？

```scala
TaskScheduler.scala //抽象类
def defaultParallelism(): Int

TaskSchedulerImpl.scala
...backend....()

SchedulerBackend.scala //trait 抽象类
//有两个实现类
//本地环境用LocalSchedulerBackend
defaultParallelism = ... "spark.default.parallelism", totalCores

//totalCores = 当前本地最大可用核数

//最后saveAsFile生成目录中文件个数等于并行度
```

makeRDD情况下，各分区如何分配数据？

```scala
//取决于ParallelColectionRDD.scala的def slice的def positions方法
//length序列长度，numSlices分区个数
//(start, end)每个分区内包含数据在原序列的索引范围
```

textFile情况下，各分区如何分配数据？

```scala
//minPartitions最小分区数量
sc.textFile("...", minPartitions = 2)
//但系统会设置超过2个分区
//spark读取文件，底层其实就是Hadoop的读取方式
FileInputFormat.java中totalSize（目录下所有文件的长度之和）
long goalSize = totalSize / (numSplits == 0?1 : numSplits);//每个分区放几个字节
//例子
totalSize = 7
goalSize = 7 / 2 = 3 Byte
7 / 3 = 2....1 (1.1) + 1 = 3 分区 (hadoop 1.1rule)
```

数据分区的分配

* 数据以行为单位进行读取

  spark读数据时用的是hadoop的读取方式，因此是一行一行读，和字节数没有关系

  偏移量不会被重新读取

* 数据读取时以偏移量为单位

  ```txt
  例子
  1@@ => 012
  2@@ => 345
  3 => 6
  ```

* 数据分区的偏移量范围的计算

  ```txt
  0-2共3个分区，每个分区3字节
  00 => [0, 3](注意是包含) => 1@@2@@(一行一行读，既然读了数据2，那下标345也一起被读到了)
  1 => [3, 6] => 3
  2 => [6, 7] => 空
  注：有疑问
  ```

  ```txt
  例子
  totalSize = 14
  goalSize = 14 / 2 = 7 Byte
  14 / 7 = 2 分区
  1234567@@ => 012345678
  89@@ => 9101112
  0 => 13
  
  [0, 7] => 1234567@@ (一行一行读，以偏移量为起始位置，因此第2个@也被读了)
  [7, 14] 从7开始，但7和8都被读了，因此从9开始 => 89@@0
  ```

#### RDD方法

1. 转换：旧RDD包装成新RDD

   flatMap, map

2. 行动：执行，触发task的执行和调度

   collect

#### 转换算子

##### 转换 - value类型

##### map与mapPartition

map的并行计算

<img src="/map-parallel.png" style="zoom:60%;" />

* RDD的计算1个分区内的数据是一个一个执行的（分区内数据执行有序）

* 不同分区的执行是无序的

  [1, 2] [3, 4]，1肯定在2之前执行，3肯定在4之前执行，但1和3谁先执行不确定

**map的效率并不高**，类似IO字节流，一个读完再读下一个

mapPartition类似缓冲区思想，优化map的执行数据，一个分区数据全拿到之后才进行操作

```scala
val mpRDD = rdd.mapPartitions(
iter => {
    iter.map(_*2)
})
//有多少个分区(numslices)就执行多少次
```

以分区为单位进行数据转换操作，但会将整个分区数据加载到内存进行引用。处理完的数据是不会被释放掉，因为存在对象的引用。在数据量大、内存小时容易出现内存溢出。

if else 判断用map还是mapPartition

[1, 2] [3, 4] 求每个分区内最大值？用map不行，因为一个个数据地读，读完就释放掉

```scala
rdd.mapPartitions(
iter => {
    List(iter.max).iterator //为了变成迭代器
})
```

map不会减少或增多数据，而mapPartition接收返回都是一个迭代器，可以增减数据

**mapPartitionsWithIndex**

分区号

[1, 2] [3, 4]

```scala
//把第二个分区的数据保留
rdd.mapPartitionsWithIndex(
(index, iter) => {
    if (index == 1)
    	iter
    else 
    	Nil.iterator
})
```

```scala
//想知道每个数据所在的分区
//(0,1)(0,2)(1,3)(1,4)
rdd.mapPartitionsWithIndex(
(index, iter) => {
    iter.map(
    	num => {
            (index, num)
        })
})
```

##### groupBy

将数据根据指定的规则进行分组，分区默认不变，但是数据会被打乱重新组合，这样的操作称为**shuffle**，极限情况下数据可能被分在同一个分区中。

例如：[1,2] [3,4] -> [1,3] [2,4]  就是将数据打乱再重新组合

一组的数据在一个分区中，但并不是说一个分区只有一个组，**分组和分区没有必然关系**，具体怎么放，底层是有逻辑的。

```scala
val rdd : RDD[Int] = sc.makeRDD(List(1,2,3,4),2)
//将数据源中每一个数据进行分组判断，根据返回的分组key进行分组
//相同的key值会放置在一个组中
def groupFunction(num:Int):Unit = {
	num % 2 //奇偶分类    
}
val groupRDD: RDD[(Int,Iterable[Int]] = rdd.groupBy(groupFunction)
//[0, [2,4]] [1, [1,3]]
```

```scala
val rdd : RDD[Int] = sc.makeRDD(List("Hello", "Hadoop", "Scala", "Spark"),2)
//相同首字母的划分成一组
val groupRDD = rdd.groupBy(_.charAt(0))
```

```scala
val timeRDD: RDD[(String, Iterable[(String, Int)])] = rdd.map(
	line => {
        val datas = line.split(" ")
        val time = datas(3)
        val sdf = new SimpleDateFormat("dd/MM/yyyy:HH:mm:ss")
        val date: Date = sdf.parse(time)
        val sdf1 = new SimpleDateFormat("HH")
        val hour: String = sdf1.format(date)
        (hour, 1)
    }
//).reduceByKey(_+_)
).groupBy(_._1) //按照时间分组
//转换一下
timeRDD.map{
    case (hour, iter) => {
        (hour, iter.size)
    }
}.collect.foreach(println)
//(06,366) (20,120) (...)
```

groupBy也可以做wordcount，不用非得用reduceBy

##### filter

可能出现**数据倾斜**（各分区数据很不均衡）

##### sample

* 第一个参数表示抽取数据后是否将数据放回（true表示放回）

* 第二个参数表示数据源中每条数据被抽取的概率

  基准值的概念 0.4表示大于0.4就出来，否则不出来

* 第三个参数表示抽取数据时随机算法的种子（每条数据概率的随机值）

  如果不传第三个参数，那么使用的是当前系统时间

```scala
//1,2,3,4,5,6,7,8,9,10
rdd.sample(
	false,
    0.4
    1
).collect.mkString(",")
//1,2,6,10
```

泊松分布、伯努利分布

数据采样有什么用？用于判断是否存在数据倾斜

##### coalesce

缩减分区

当spark程序中存在过多小任务时，通过coalesce方法收缩合并分区，减少分区个数，减小任务调度成本

```scala
rdd.coalesce(2)
rdd.coalesce(2, true)//让它shuffle，使数据分布均衡
```

也可以扩大分区，但扩大的同时不shuffle，则无意义，因为数据不重新组合

##### rePartition

coalesce+shuffle参数固定为true

##### sort

```scala
rdd.sortBy(t=>t._1.toInt, false) //默认是true升序
```

中间存在shuffle操作，因为数据存在打乱重新组合

##### 转换-双value类型

```scala
//rdd1 1,2,3,4
//rdd2 3,4,5,6
//交集
rdd3 = rdd1.intersection(rdd2)
//并集
rdd4 = rdd1.union(rdd2)
//差集
rdd5 = rdd1.subtract(rdd2)
//拉链 [1-3,2-4,3-5,4-6]
rdd6: RDD[(Int, Int)] = rdd1.zip(rdd2)
```

##### 转换-key value类型

##### partitionBy

根据指定的分区规则对数据进行重分区

spark默认分区器是hashPartitioner

```scala
val rdd = sc.makeRDD(List(1,2,3,4))
val mapRDD:RDD[(Int,Int)] = rdd.map((_,1)) //int变成tuple类型（变成k-v类型）
//这里用了隐式转换，当程序编译出现错误时，会尝试在整个作用域范围之内查找转换规则，看是否能转换成特定类型来让其通过
//也叫二次编译
//RDD -> PairRDDFunctions
//RDD.scala中存在一个伴生对象object RDD，里面有隐式函数rddToPairRDDFunctions[K,V](rdd:RDD[(K,V)])
//隐式转换遵守OCP开发原则
mapRDD.partitionBy(new HashPartitioner(partitions=2)).saveAsTextFile("output")
```

scala中==就是一个做了非空校验的equals

RangePartitioner常用于排序，因为排序用范围比较多

##### reduceByKey

分组+聚合

存在 **shuffle** 操作

```scala
sc.makeRDD(List(("a",1),("b",2),("c",3)))
rdd1.reduceByKey(_+_)
rdd1.reduceByKey(_+_, 2)
```

```scala
rdd = sc.makeRDD(List(
	("a",1),("a",2),("a",3),("b",4)	
))
//隐藏了一个分组的概念
//scala语言中一般聚合操作都是两两聚合
val reduceRDD: RDD[(String,Int)] = rdd.reduceByKey((x:Int, y:Int) => {x+y})
//reduceByKey中若key的数据只有一个，则不会参与运算
```

##### groupByKey

将数据源中的数据，相同的key分到一个组中，形成一个对偶元组

元组中第一个元素是key

元组中第二个元素是相同key的value集合

是一个 **shuffle** 操作

```scala
sc.makeRDD(List(("a",1),("b",2),("c",3)))
rdd1.groupByKey()
rdd1.groupByKey(2)
rdd1.groupByKey(new HashPartitioner(2))
```

```scala
val rdd = sc.makeRDD(List(
	("a",1),("a",2),("a",3),("b",4)	
))
val groupRDD:RDD[(String,Iterable[Int])] = rdd.groupByKey()
//(a,CompactBuffer(1,2,3))
//(b,...(4))
val groupRDD1:RDD[(String,Iterable[(String,Int)])] = rdd.groupBy(_._1)
//不会把value独立出来，因为分组的key不确定
```

有shuffle操作不能并行计算，需要等待，如果在内存中等待，内存可能不够用，因此必须落盘处理

RDD与RDD之间存在File IO操作，因此shuffle操作的性能非常低

核心区别是

* reduceByKey是相同key的value两两聚合，能在起始RDD进行提前聚合，能有效减少落盘数据量

  分区内和分区间计算规则相同

* groupByKey没有聚合概念，聚合是通过之后的一个map来做

##### aggregateByKey

分区内和分区间计算规则可以独立设定

```scala
val rdd = sc.makeRDD(List(
	("a",1),("a",2),("a",3),("b",4)	
),2)
//aggregateByKey存在函数柯里化，有两个参数列表
//第一个参数列表需要一个参数，表示为初始值
//   主要用于当碰见第一个key时，和value进行分区内计算
//第二个参数列表需要两个参数
//   第一个参数表示分区内计算规则
//   第二个...分区间...
rdd.aggregateByKey(zeroValue=0)(
	(x,y) => math.max(x,y),
    (x,y) => x + y
).collect

//获取相同key的数据的平均值 => (a,3),(b,4)
val newRDD:RDD[(String, (Int,Int))] = rdd.aggregateByKey((0,0))(
	(t,v) => {
        t._1 + v, t._2 + 1
    },
    (t1,t2) => {
        (t1._1 + t2._1, t1._2, t2._2)
    }
)
//key不变，value变
//RDD[(String, Int)]
.mapValues{
    case (num,cnt) => {
        num / cnt
    }
}
```

##### foldByKey

分区内和分区间计算规则相同

（wordcount）

##### combineByKey

将相同key的第一个数据进行结构的转换

##### join

(K,V) (K,W) -> (K,(V,W))

```scala
val rdd1 = sc.makeRDD(List(
	("a",1),("b",2),("c",3)
))
val rdd2 = sc.makeRDD(List(
	("a",4),("b",5),("c",6)
))
//内连接
rdd1.join(rdd2)
//相同key没有，则不会出现在结果中
//相同key有多个元素，则会依次匹配
//可能出现笛卡尔乘积，会有内存风险，导致性能降低
//其实底层实现是笛卡尔积？
```

尽量少用join，看是否有代替

#### 行动算子

触发整个计算（作业job）的执行

##### collect

看RDD.scala，def collect()，调用环境对象sc的runJob()

```scala
DAGScheduler.scala
dagScheduler.runJob
submitJob
eventProcessLoop.post(JobSubmitted()) //提交消息触发事件
def handleJobSubmitted()//handle表示处理这个事件
val job = new ActiveJob()
//总结：底层代码中会创建ActiveJob，并提交执行
```

collect方法会将不同分区的数据按照分区顺序采集到Driver端内存中，形成数组

`val ints: Array[Int] = rdd.collect()`

##### reduce

直接出结果，因为触发作业的执行

两两聚合

```scala
//1,2,3,4
rdd.reduce(_+_) //10
```

 **count, first, take**

##### aggregate

初始值，分区内计算规则，分区间计算规则

```scala
//1,2,3,4
val result = rdd.aggregate(zeroValue = 0)(_+_, _+_)
//10
//0+1+2=3, 0+3+4=7 => 3+7=10
```

* aggregateByKey初始值只会参与分区内计算
* aggregate初始值会参与...，还会参与分区间计算

**fold** agg简化版

##### save

saveAsSeqenceFile要求数据格式必须为k-v类型

##### foreach

分布式遍历RDD中的每一个元素

没有顺序概念，并没有按照顺序采集

```scala
//driver端内存集合进行打印操作
rdd.collect().foreach(println)
//executor端内存数据进行打印操作
rdd.foreach(println)
```

#### 算子

* scala集合对象的方法都是在同一个节点的内存中完成的

* RDD的方法可以将计算逻辑发送到Executor端执行

为了区分，因此把RDD的方法称为算子。

**RDD的方法外部的操作都是在Dirver端执行，而方法内部的逻辑代码是在Executor端执行**

### RDD序列化 

#### 闭包检测

在函数式编程中，算子内经常用到算子外的数据，这样就形成了闭包效果

```scala
val rdd = sc.makeRDD(List(1,2,3,4))
val user = new User() //算子外部的代码在driver端执行，因此在driver端构建了一个对象User
rdd.foreach(
    //下面代码在exe端执行（打印）
	num => {
        //用到了User，而User在driver端，因此需要在网络中传递User
        //因此需要序列化
        println("age = " + (user.age + num))
    }
)
sc.stop()
//main函数之外
/**
class User {
    var age: Int = 30
}
**/
//出现异常，原因是User没有序列化
class User extends Serializable {
    var age: Int = 30
}
//也可以写成
//样例类在编译时，会自动混入序列化特质
case class User() {
    var age: Int = 30
}

//函数式编程含有闭包概念
//RDD算子中传递的函数是会包含闭包操作，那么就会进行检测功能（把外部变量user引入内部代码，检测是否能传入）
//闭包指的是num => {...}
//foreach源码
//sc.clean(f)
//ClosureCleaner.clean(f,checkSerializable)闭包清除器，把不需要的功能清楚，check...就是检查序列化
//继续点击clean，里面有判断!isClosure(func.getClass)
if(checkS...) {
    ensureS...(func) //尝试序列化，不能序列化则抛出错误
}
```

闭包检测是分布式执行所需要注意的地方之一

类的构造参数其实是类的属性，构造参数需要进行闭包检测，其实就等同于类进行闭包检测

#### Kryo序列化框架

Java序列化能序列化任何的类（产生的信息全），但比较重（字节多），序列化后对象的提交也比较大。

Spark从2.0开始支持另一种kryo序列机制，kryo速度是serializable的10倍。

RDD在shuffle数据时，简单数据类型、数组和字节串类型已经在spark内部使用kryo来序列化。

**注意：**即使使用kryo，也要继承serializable接口

### RDD依赖关系

#### RDD血缘关系

多个连续RDD的依赖关系叫血缘关系

每个RDD会保存血缘关系

容错性：一旦出现错误，可以根据血缘关系将数据源重新读取进行计算

#### RDD重用

一个RDD重复使用，则需要从头再次执行来获取数据

有什么办法提高性能？不重复读取？

持久化：在公共RDD节点处先保存在内存或文件中

只会在后面触发了action操作，才会执行这一步的持久化

```scala
mapRDD.cache()//持久化在jvm堆内存中
mapRDD.persist(StorageLever. ...)
//MEMORY_ONLY, DISK_ONLY ...
//落盘时保存为临时文件，运行完会删除
```

#### CheckPoint

在中间阶段做检查点容错，将RDD中间结果落盘。

```scala
sc.setCheckPointDir(path)
//需要指定路径，因为运行完毕后不删除
//一般保存路径在分布式存储系统中（HDFS）
mapRDD.checkpoint()
```

也含有RDD重用功能，但性能比perisist低，一般情况下与cache联合使用

* cache会在血缘关系中添加新的依赖，一旦出现问题可以重头读取数据

* checkpoint在执行过程中会切断血缘关系，重新建立新的血缘关系

  checkpoint等同于改变数据源

### Stage

```scala
DAGScheduler.scala
finalStage = createResultStage()//划分阶段
def createResultStage {
    ...
    getOrCreateParentStages()
    new ResultStage()
}
def getOr...{
    //获取shuffle依赖
    getShuffleDependencies(rdd).map {
        //把每一个shuffle都转换成新的阶段
        shuffleDep => getOrCreateShuffleMapStage(shuffleDep, firstJobId)
    }.toList
}
def getShuffleDependencies {
    ...
    val parents = new HashSet[ShuffleDependency[_,_,_]]
    val waitingForVisit = new ListBuffer[RDD[_]]
    //遍历依赖树
    waitingForVisit += rdd 
    while(waitingForVisit.nonEmpty) {
        ...
        //判断是否是shuffle依赖
        //是的话把shuffle依赖加进parents中
        //不是的话继续将dependency入队，继续遍历
    }
    //最后返回parents
}
def getOrCreateShuffleMapStage {
    val stage = new ShuffleMapStage()
}
```

当RDD中存在shuffle依赖时，会自动增加一个stage

stage数 = shuffle数 + 1

resultStage数 = 1，最后需要执行的阶段

### 任务划分

* Application：初始化一个sc即生成一个App
* Job：一个action算子就生成一个job
* Stage：stage等于宽依赖（shuffle）个数加1
* Task：一个stage中，最后一个RDD的分区数就是task的个数

app -> job -> stage -> task 每一层都是1对n关系

#### Job

```scala
DAGScheduler.scala
def handleJobSubmitted() {
    ...
    try {
        finalStage = createResultStage()
    }
    ...submitStage(finalStage)
}
def submitStage(stage: Stage) {
 	//是否有上一级阶段
    submitMissingTasks(stage, jobId.get)
}
//call when stage's parents are available and we can now do its tasks
def submitMissingTasks() {
    ...
    //当前阶段中所有的task
    val tasks: Seq[Task[_]] = try {
        //匹配stage类型
    }
}
```

### 分区器

```scala
val parRDD = rdd.partitionBy(new MyPartitioner)
//main函数外
//自定义分区器
class MyPartition extends Partitioner {
    override def numPartitions: Int = 3
    //根据数据的key值返回数据所在的分区索引（分区号），从0开始
    override def getPartition(key: Any): Int = {
        key match {
            case "nba" => 0
            case "wnba" => 1
            case _ => 2
        }
    }
}
```

### 累加器

```scala
var sum = 0
//val i: Int = rdd.reduce(_+_)
rdd.foreach(
	num => {
        sum += num
    }
)
//有问题，因为实际是分布式计算，在exe计算完后，exe端的sum变量不会返回给driver，而输出是在driver输出
//这时就需要累加器，在计算完毕后可以把结果返回给driver
```

累加器用来把exe端变量信息聚合到driver端，在driver程序中定义的变量，在exe端的每个task都会得到这个变量的一份新的副本，每个task更新这些副本的值后，传回driver端进行merge。

```scala
val sumAcc = sc.longAccumulator(name="sum")
rdd.foreach(
	num => {
        sumAcc.add(num)
    }
)
println(sumAcc.value)
//有多种累加器类型，包括集合类型
```

* 少加

  如果不是action算子，则不会执行累加器

* 多加

  累加器是全局共享的

  算子后多调用一次action算子，则会多算

“只写”代表exe之间不能互相访问累加器的值

**技巧点** 累加器也可以代替shuffle

WordCount

```scala
val rdd = sc.makeRDD(List("hello","spark","hello"))
//rdd.map((_,1)),reduceByKey(_+_)

//创建累加器对象
val wcAcc = new MyAccumulator()
//向spark进行注册
sc.register(wcAcc, name="wordCountAcc")
rdd.foreach(
    word => {
        wcAcc.add(word)
    }
)
println(wcAcc.value)

//main外面
//继承的Accu...需要定义泛型
//IN: 单词用String表示
//OUT: map键值对
class MyAccumulator extends AccumulatorV2[String,mutable.Map[String,Long]] {
    private var wcMap = mutable.Map[String, Long]()
    //判断是否为初始状态
    override def isZero: Boolean = {
        wcMap.isEmpty //为空就是初始状态
    }
    override def copy(): AccumulatorV2[String,mutable.Map[String,Long]] = {
        new MyAccumulator()
    }
    override def reset(): Unit = {
        wcMap.clear()
    }
    //获取累加器需要计算的值
    override def add(word: String): Unit = {
        //原来的 + 当前出现1次
        val newCnt = wcMap.getOrElse(word, 0L) + 1
        wcMap.update(word, newCnt)
    }
    //driver合并多个累加器
    override def merge(other: AccumulatorV2[String,mutable.Map[String,Long]]): Unit = {
        val map1 = this.wcMap
        val map2 = other.value
        map2.foreach{
            case (word,count) => {
                val newCount = map1.getOrElse(word,0L)+count
                map1.update(word,newCount)
            }
        }
    }
    //获取累加器结果
    override def value: mutable.Map[String, Long] = {
        wcMap
    }
}
```

### 广播变量

可以代替join（join包含笛卡尔积以及shuffle）

```scala
val rdd1 = sc.makeRDD(List(
	("a",1),("b",2),("c",3)
))
//val rdd2 = sc.makeRDD(List(
//	("a",4),("b",5),("c",6)
//))

//val joinRDD:RDD[(String,(Int,Int))] = rdd1.join(rdd2)
//joinRDD.collect().foreach(println)

val map = mutable.Map(("a",4),("b",5),("c",6))
rdd1.map{
    case (w,c) => {
        val l:Int = map.getOrElse(w,0)
        (w,(c,l))
    }
}.collect().foreach(...)
//以上方法可以代替join，避免笛卡尔积和shuffle
//但是数据量很多的话，每个task里都需要用到map
```

数据量很多的话，每个task里都需要用到map

10个分区（task），但exe只有1个，只有1个cpu

假设1个map有100万条数据，则10个task共有1000万条数据

其中这900万条数据都是冗余的

闭包数据都是以task为单位发送的，每个任务中包含闭包数据可能会导致一个exe中含有大量重复的数据，并且占用大量的内存

**技巧点**

exe其实就1个jvm，所以在启动时，会自动分配内存。完全可以将任务中的闭包数据放置在exe内存中，达到共享的目的

但是不能可改，否则线程不安全

Spark中的广播变量就可以将闭包的数据保存在exe的内存中

广播变量不能更改

```scala
val rdd1 = sc.makeRDD(List(
	("a",1),("b",2),("c",3)
))
val map = mutable.Map(("a",4),("b",5),("c",6))
//封装广播变量
val bc: Broadcast[mutable.Map[String,Int]] = sc.broadcast(map)
rdd1.map{
    case (w,c) => {
        //访问广播变量
        val l:Int = bc.value.getOrElse(w,0)
        (w,(c,l))
    }
}.collect().foreach(...)
```

