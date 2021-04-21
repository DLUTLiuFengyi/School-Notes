---
typora-root-url: pic
---

### 总览



### 环境准备

特指yarn集群

#### SparkSubmit

```shell
java xxx #启动一个java虚拟机执行某个类（启动一个进程）
java org.apache.spark.deploy.SparkSubmit
/bin/java org.apache.spark.deploy.yarn.ApplicationMaster
/bin/java org.apache.spark.executor.YarnCoarseGrainedExecutorBackend
#YarnCoarseGrainedExecutorBackend是executor的通信后台，是一个专门的进程

java HelloWorld

jvm => Process(SparkSubmit)
```

```scala
org.apache.spark.deploy.SparkSubmit.scala
执行其main方法
doSubmit()
parseArgument -> SparkSubmitArguments.scala -> SparkSubmitOptionParser.java
```

#### 1 准备提交环境

`(childArgs, childClasspath, sparkconf, childMainClass) = prepareSubmitEnvironment(args)`

`childMainClass当前是org.apache.spark.deploy.yarn.YarnClusterApplication`

```scala
Client.scala
class YarnClusterApplication
start()
new Client(new ClientArguments(args)).run() //重要

class Client
val yarnClient = YarnClient.createYarnClient
->
new YarnClientImpl()
->
YarnClientImpl.java
protected ApplicationClientProtocol rmClient;//ResourceManager
```

```scala
appArgs.action默认是SUBMIT模式 -> submit() -> doRunMain() -> runMain() -> prepareSubmitEnvironment(args)//重要方法

val loader = getSubmitClassLoader(sparkConf)
mainClass = Utils.classForName(childMainClass)
//类加载器，根据一个类的名称去得到类的信息
//判断是否继承了SparkApplication这个类，如果是就反射创建这个对象否则就new一个JavaMainApplication(mainClass)，最后会新建出一个app
//childMainClass从哪来？从prepare...那个函数赋值而来
...
app.start(childArgs.toArray, sparkConf)
```

#### 2 提交应用程序

submitApplication()

与yarn集群的RM连接，向其提交应用。RM得到指令后让某个节点启动ApplicationMaster，启动命令是/bin/java

```scala
Client.scala
def run()
//全局yarn的应用id，用于应用程序状态进行操作以及执行包装
this.appId = submitApplication()
->
yarnClient.init(hadoopConf)
yarnClient.start()
//告诉RM要创建一个应用
val newApp = yarnClient.createApplication()
//得到响应
val newAppResponse = newApp.getNewApplicationResponse()
//响应之后得到全局id
appId = newAppResponse.getApp...Id()
...
//创建容器的启动环境以及执行环境
//container在yarn中是用来解耦合的
val containerContext = createContainerLaunchContext(newAppResponse)
//提交的环境
val appContext = createApplicationSubmissionContext(newApp,containerContext)
//最后，建立与RM的连接，并提交和监控app
yarnClient.submitApplication(appContext)
launcherBackend.setAppId(appId)

createContainerLaunchContext
含有 command for the ApplicationMaster
Seq(Environment.JAVA_HOME.$$() + "/bin/java", "-server")...
```

2.1 

`amClass = "org.apache.spark.deploy.yarn.ApplicationMaster"`

`amClass = "org.apache.spark.deploy.yarn.ExecutorLauncher"`

```scala
ApplicationMaster.scala //里面有main方法
main()
val amArgs = new ApplicationMasterArguments(args)//模式匹配解析参数（参数一直在传，一直没用上）
val sparkConf = new SparkConf()
...
val yarnConf = new YarnConfiguration(..(sparkConf))
master = new ApplicationMaster(amArgs,sparkConf,yarnConf)
-> //此构造函数中
val client = new YarnRMClient()
--> //此构造函数中
var amClient: AMRMClient[ContainerRequest]//AM连接RM的客户端，对应2.那一步

master在后面有master.run()
->
//如果是集群模式
runDriver()
//否则
runExecutorLauncher()
```

2.2 ApplicationMaster  

* runDriver

```scala
//接上面
//runDriver()中
userClassThread = startUserApplication()//重要
...
//线程的阻塞，等待sparkContext上下文环境对象，直到spark.driver.port属性被执行用户class的Thread设置好
val sc = ThreadUtil.awaitResult(sparkContextPromise.future,Duration(...))
//如果上下文环境不为空
//rpcEnv是通信环境
//注册AM，申请资源，yarn当前有哪些资源可以用
```

* 启动用户的应用程序

  startUserApplication

* 处理可用于分配的容器

  handleAllocatedContainers

* 运行已分配容器

  runAllocatedContainers

* 准备指令

  prepareCommand

* 向指定NM启动容器

  nmClient.startContainer

#### 3 启动Driver线程

AM根据参数启动Driver线程，并初始化SparkContex

```scala
//接上，仍在App...Master.scala
//startUserApplicationMaster函数内
//类加载器
val mainMethod = userClassLoader.loadClass(args.userClass)
.getMethod("main", classOf[Array[String]])//从指定类中找到main方法
//userClass是一个参数类，在App...MasterArguments.scala中，--class
...
//ApplicationMaster根据参数启动driver线程
val userThread = new Thread {
    run() = {
        //判断main方法是否是静态的，是的话invoke main
        //执行wordcount、SparkPi等main函数
    }
}
...
userThread.setName("Driver")//线程名字是driver
userThread.start()
//然后返回userThread
```

#### 4 注册AM 去申请资源

跟yarn做连接（NodeManager中的ApplicationMaster中的YarnRMClient去连接RM）

```scala
//接上上块代码，runDriver()中
//如果上下文环境不为空
//注册AM
registerAM(...)
val driverRef = rpcEnv.setupEndpointRef(...)
//分配器
createAllocator(driverRef,userConf,rpcEnv,...)
->
//这里的client是YarnRMClient
allocator = client.createAllocator(yarnConf,_sparkConf,..driverUrl...)
//通过分配器得到可分配的资源
allocator.allocateResources()
```

#### 5 返回资源可用列表

RM返回给NodeManager

```scala
//上面代码最后的allocateResources()函数
YarnAllocator.scala
allocateResources()
//采集到资源信息
val allocateResponse = amClient.allocate(...)
//可分配容器，现在资源以container方式放回给我们
val allocatedContainer = allocateResponse.getAllocatedContainers()
//假设有可分配容器，则要处理
handleAllocatedContainers(all..Con...asScala)
->
//把可分配容器进行分类
//是不是在同一台主机上
val remainingAfterHostMatches = new ArrayBuffer[Container]
...
//分配好容器后，run
runAllocatedContainers(containersToUse)
```

<img src="/rack-resource-host.png" style="zoom:50%;" />

**概念：** 首先位置，一个task应该发给哪个container执行，发给1还是2？

![](/spark1.png)

```scala
//接上面代码
YarnAllocator.scala
runAllocatedContainers(containersToUse)//参数是一个ArrayBuffer[Container]
->
//Launches executors in the allocated containers
//for循环，挨个遍历能够使用的容器
...
//如果当前运行executor数量小于目标executor数量
if (runningExecutor.size()<targetNumExecutors) {
    //启动containers
    if(launchContainers) {
        //用线程方式启动
        //意味在当前AllicationMaster中有一个线程池
        launcherPool.execute(()=>{
            new ExecutorRunnable(相关配置参数).run()//这个run
        })
    }
}
//上面的run在ExecutorRunnable.scala
//NMClient意味着创建与其他NodeManager的关联
run() {
    nmClient = NMClient.createNMClient()
    nmClient.init(conf)
    nmClient.start()
    startContainer()
}
startContainer()
->
//发送开始request给ContainerManager
//启动容器，把ctx环境信息传过去
//这里是找到新的NodeManager让它启动容器
nmClient.startContainer(container.get,ctx)
... ctx.setCommand(commands.asJava)
val commands = prepareCommand()
->
//发现里面又是/bin/java指令，执行YarnCoarseGrainedExecutorBackend
```

#### 6 启动Executor

黄色是线程，绿色是进程

<img src="/spark2.png" style="zoom:50%;" />

```scala
YarnCoarseGrainedExecutorBackend.scala
main方法
CoarseGrainedExecutorBackend.run(...)
->
CoarseGrainedExecutorBackend.scala
val fetcher = RpcEnv.create()//fetcher找到driver
...
val env = SparkEnv.createExecutorEnv(...)//创建运行时环境
//在通信环境中增加一个通信终端
//把创建出来的对象backendCreateFn设置为终端
env.rpcEnv.setupEndpoint(name="Executor",...)
```

**概念**

* RPCEnv 通信环境
* Backend 后台
* Endpoint 终端

```scala
//接上面 setupEndpoint
RpcEnv.scala
def setupEndpoint//抽象
//在NettyRpcEnv.scala中实现
//注册rpc通信终端
dispatcher.registerRpcEndpoint(name,endpoint)//对象 名称
->
Dispatcher.scala
def registerRpcEndpoint()
//通信地址
val addr = RpcEndpointAddress(nettyEnv.address,name)
//通信引用
val endpointRef = new NettyRpcEndpointRef()
...
//消息循环器
var messageLoop
//匹配，若匹配成功
//a message loop that is dedicated to a single RPC endpoint
new DedicatedMessageLoop()
->
//在此类中有一个inbox和一个threadpool
//inbox是收件箱，存储来自一个rpc终端的messages以及将messages post到
//inbox可以发消息（OnStart），发给自己，告诉自己要onstart
//通信终端RpcEndpoint.scala
//通信环境中有一个生命周期：constructor->onStart->receive*->onStop

//收件箱置为onstart后，CoarseGrainedExecutorBackend（继承自IsolatedRpcEndpoint）就能收到消息，就会调用其onStart()方法
```

<img src="/spark3.png" style="zoom:50%;" />

```scala
//接上
CoarseGrainedExecutorBackend.scala
def oNnStart()
rpcEnv.asyncSetupEndpointRefByURI(driverUrl).flatMap{
    //得到driver
    //拿到后向之前的NM中的ApplicationMaster中的driver发一个请求
    //注册当前的executor
}
```

#### 7 注册Executor

```scala
SparkContext.scala
//里面有成员 通信后台
var _schedulerBackend: SchedulerBackend = _ //靠这个与后台通信
//是个trait，实现有CoarseGrainedSchedulerBackend.scala
CoarseGrainedSchedulerBackend.scala
//是一个通信终端，有onStart(), 有receive()
def receiveAndReply()
case RegisterExecutor//在这里把消息收到
//前面CoarseGrainedExecutorBackend.scala
def onStart() {
    ref.ask[](RegisterExecutor(...))//发消息
}
//然后这里的def receiveAndReply(){case RegisterExecutor}就是收到消息
//收到消息后把当前环境的一些数量增加，比如核数 executor数
//最后回复一个true，代表注册executor成功
context.reply(response=true)
```

<img src="/spark4.png" style="zoom:50%;" />

#### 8 注册成功

```scala
//注册成功后
CoarseGrainedExecutorBackend.scala
def receive {
    //这一步非常重要
    //这个才是真正的Executor，是一个计算对象
    executor = new Executor(executorId,hostname,env...)
    //创建后，发送
    driver.send(LaunchedExecutor(executorId))
}
//这里的LaunchedExecutor函数，在CoarseGrainedSchedulerBackend.scala
```

```scala
CoarseGrainedSchedulerBackend.scala
case LaunchedExecutor(executorId) => 
//增加核数
def makeOffers(executorId)
```

#### 9 创建Executor计算对象

<img src="/spark5.png" style="zoom:50%;" />

**至此，Driver、Executor、ResourceManager、NodeManager已准备好，剩下的就是计算工作，如任务切分、调度和执行等**

对driver来说，有两条线，一条线是申请资源，一条线是执行计算

刚刚的ApplicationMaster.scala的后面，有

`resumeDriver()`

让driver继续执行，让wordcount继续往下走

```scala
SparkContext.scala
_taskScheduler.postStartHook()//告诉程序，准备工作已完成
->
TaskScheduler.scala//是个接口
//实现有TaskSchedulerImpl -> YarnScheduler -> YarnClusterScheduler
YarnClusterScheduler.scala
def postStartHook() {
    ApplicationMaster.sparkContextInitialized(sc)//这一行让刚才App.Master中runDriver()函数中的val sc = ThreadUtils...线程阻塞的那一步继续往下执行
    super.postStartHook()
}
super ->
def waitBackendReady() {
    //状态的等待
    while(!backend.isReady) {
        //等待资源ready后的通知
    }
}
//Applicationmaster.scala的resumeDriver()中会通知
sparkContextPromise.notify()
//driver往下执行，进入计算阶段
```

**综上**

* Driver是一个线程，它通过反射执行业务程序的main方法
* Executor有两个
  * YarnCoarseGrainedExecutorBackend 通信后台（通常意义）
  * Executor 计算对象（内部属性）

<img src="/steps.png" style="zoom:50%;" />

反向注册是第7步，因为Executor（绿色）是ApplicationMaster申请启动的，启动后反向注册给AppM，目的是告诉有哪些资源已经准备好了。

上图还不够准确，因为两条线是**交替阻塞**关系。

* 提交时，driver线程执行时，右边处于阻塞态
* driver反射执行main方法后，去创建sparkContext并完成初始化后，会通知右边让右边继续执行，此时左边（懒执行前）处于阻塞态
* 右边完成反向注册后，告诉左边继续执行，左边才开始计算

#### Yarn集群模式

yarn的cluster与client模式区别在于driver运行在哪里

<img src="/spark6.png" style="zoom:50%;" />

```scala
//根据childMainClass定位
SparkSubmit.scala
(...) = prepareSubmitEnvironment()
->
if (deployMode == CLIENT) {
    childMainClass = args.mainClass//点击
}
->
SparkSubmitArguments.scala
case CLASS => mainClass = value
->
CLASS = "--class"
//等同于把--class(WordCount, SparkPi)放在YCA的Client中执行
```

client模式时，driver其实是在原图的YarnClusterApplication中执行

<img src="/spark7.png" style="zoom:50%;" />

<img src="/spark8.png" style="zoom:50%;" />

#### Standalone模式

* Master，类似于RM

  一个进程

  资源调度和分配，集群的监控

* Worker，类似于NM

  一个进程

  * 用自己的内存存储RDD某个或某些partition
  * 启动其他进程和线程（Executor），对RDD上的partition进行并行的处理和计算

##### Standalone cluster

<img src="/stand-clu.png" style="zoom:50%;" />

* 任务提交后，master会找到一个worker启动driver
* driver启动后向master注册app，master根据submit脚本的资源需求找到内部资源至少可以启动一个executor的所有worker，然后在这些worker之间分配executor
* worker上的executor启动后会向driver反向注册
* 所有的executor注册完成后，driver开始执行main函数，之后指定到action算子时，开始划分stage
* 每个stage生成对应的taskset，之后将task分发到各个executor上执行

##### Standalone client

把driver提到外面执行

<img src="/stand-cli.png" style="zoom:50%;" />

* **driver在任务提交的本地机器上运行**

* driver启动后master注册app

* master根据submit脚本的资源需求找到内部资源至少可以启动一个executor的所有worker，然后在这些worker中分配exe

* worker上的exe启动后会向driver反向注册

* 所有exe注册完成后，driver开始执行main函数，之后执行到action算子时，开始划分stage，每个stage生成对应的taskset，之后将task分发到各个executor上执行

  

### 组件通信

Netty，一个通信框架，支持AIO（异步通信）

* BIO 阻塞IO

* NIO 非阻塞IO

  缺点是还需要时不时地询问一下数据传完了没有

* AIO 异步非阻塞式IO

  提前跟发送方约定好一个时间段后数据传完，双方各干各的

  Linux对AIO支持不好，Windows好

  Linux采用epoll方式模仿AIO

```scala
NettyUtils.scala
/** Returns the correct ServerSocketChannel class based on IOMode. */
  public static Class<? extends ServerChannel> getServerChannelClass(IOMode mode) {
    switch (mode) {
      case NIO:
        return NioServerSocketChannel.class;
      case EPOLL:
        return EpollServerSocketChannel.class;
      default:
        throw new IllegalArgumentException("Unknown io mode: " + mode);
    }
  }
```

* NettyRpcEnv
* RpcEndpoint 用于发数据
* RpcEndpointRef 用于收数据
  * **收件箱** Inbox 接收到的数据放在收件箱中
  * **发件箱** outboxes

<img src="/io1.png" style="zoom:70%;" />

还有多个transport client，与sever建立连接发送数据

最后，最基本的通信环境如图

<img src="/io2.png" style="zoom:70%;" />

基于Netty的新RPC框架借鉴了Akka的设计，基于actor模型

Actor模型类似于收发邮件

<img src="/io3.png" style="zoom:70%;" />

![](/io4.png)

Endpoint(Client/Master/Worker)有1个InBox和n个OutBox（取决于此EP要与几个EP通信），Endpoint接收到的消息被写入InBox，发送出去的消息写入OutBox并被发送到其他EP的IB中。

每个节点都有自己的通信环境

#### Driver与Executor

```scala
//Driver
class DriverEndpoint extends IsolatedRpcEndpoint
//Executor
class CoarseGrainedExecutorBackend extends IsolatedRpcEndpoint
```

#### 通信架构图

![](/io5.png)

* TClient向TServer发送消息（Netty网络通信）
* 消息从TS传出被Dispatcher接收到
* DP传到收件箱Inbox（本地指令）
* inbox进行消息，处理邮件（消费FIFO）
* （RpcEndpoint）处理过程中需要返回给DP（SEND）
* DP分发给Outbox（远程指令）
* OutboxMessage -> 转发给TClient

##### RpcEndpoint

RPC通信终端，spark对每个节点（Client/Master/Worker）都称为一个终端，且都实现RpcEndpoint接口，内部根据不同的消息和不同的业务处理，如果需要发送（询问）则调用Dispatcher。在spark中所有的终端都存在生命周期：

* Constructor
* onStart
* receive*
* onStop

##### RpcEnv

rpc上下文环境，每个rpc终端运行时依赖的上下文环境称之为RpcEnv，现在spark使用NettyRpcEnv

##### Dispatcher

消息分发/调度器，针对于RPC终端需要发送的远程消息或从远程RPC接收到的消息，分发到对应的指令收件箱（发件箱）。

* 如果指令接收方是自己，则存入收件箱
* 如果指令接收方不是自己，则放入发件箱

##### Inbox

收件箱，DP在每次向inbox存入消息时，都将对应EndpointData加入内部ReceiverQueue中，另外DP创建时会启动一个单独线程进行轮询ReceiverQueue，进行收件箱消息消费。

##### RpcEndpointRef

RpcEndpointRef是对远程RpcEndpoint的一个引用。当我们需要向一个具体的RpcEndpoint发送消息时，一般我们需要获取到该RpcEndpoint的引用，然后通过该应用发送消息。

##### OutBox

指令消息发件箱。对于当前RpcEndpoint来说，一个目标RpcEndpoint对应一个发件箱，如果向多个目标RpcEndpoint发送消息，则有多个OutBox。当消息放入Outbox后，紧接着通过TransportClient将消息发送出去。消息放入发件箱以及发送过程是在同一个线程中进行。

##### RpcAddress

表示远程的RpcEndpointRef的地址，Host+Port

##### TransportClient

Netty通信客户端，一个Outbox对应一个TransportClient，TC不断轮询Outbox，根据OB消息的receive信息，请求对应的远程TransportServer

##### TransportServer

Netty通信服务端，一个RpcEndpoint对应一个TransportServer，接收远程消息后调用Dispatcher分发消息至对应收发件箱



### 应用程序的执行

Driver线程执行用户程序的main方法，然后把环境创建出来，执行业务逻辑。

#### SparkContext

内含

* SparkConf  配置对象，基础环境
* SparkEnv  环境对象，通信环境
* SchedulerBackend  通信后台，后台是要拿来通信的，而Executor就与这个后台通信
* TaskScheduler  task调度，专门调度task（task发给谁）
* DAGScheduler  stage调度，stage划分及task切分

#### RDD依赖

Dependency.scala

#### 阶段的划分

```scala
//创建stage
createResultStage
//获取或创建上级stage
getOrCreateParentStages
    getShuffleDependencies(rdd).map {
        shuffleDep => getOrGreateShuffleMapStage(shuffleDep,firstJobId)
    }.toList
//获取或创建shuffleMap阶段（写磁盘之前的阶段）
getOrCreateShuffleMapStage
```

```scala
xxx.collect() //行动算子
->
RDD.scala sc.runJob()
->
SparkContext.scala runJob
->
dagScheduler.runJob
->
DAGScheduler.scala
submitJob()
->
eventProcessLoop.post(JobSubmitted())//事件JobSubmitted
->
EventLoop.scala
//往eventQueue中放事件
eventQueue.put(event)
->
eventThread = new Thread(name)
run() //此方法从eventQueue中取出事件
val event = eventQueue.take()
//取出事件后
onReceive(event)//在DAGScheduler中有实现
->
//the main event loop of the DAG scheduler
def onReceive(event)
doOnReceive()
->
//往事件队列中发一条消息，收到消息后，对event作一个模式匹配
event match {
    case JobSubmitted() => dagScheduler.handleJobSubmitted()
}
->
def handleJobSubmitted() {
    //进行阶段的划分
    finalStage = createResultStage()
}
->
val stage = new ResultStage(id,rdd,func,partitions,parents,jobId,callSite)
//此rdd就是当前处理的rdd (this)
//此parents是
val parents = getOrCreateParentStages(rdd, jobId)
->
def getOrCreateParentStages(rdd:RDD[_], firstJobId:Int):List[Stage] = {
    //此rdd是最后的rdd (ShuffleRDD)
    getShuffleDependencies(rdd).map {
        shuffleDep => getOrGreateShuffleMapStage(shuffleDep,firstJobId)
    }.toList
}
->
//获取shuffle依赖
def getShuffleDependencies()
//核心逻辑：判断RDD中的依赖关系是不是shuffle依赖
toVisit.dependencies.foreach {
    case shuffleDep: ShuffleDependency[_,_,_] => parants += shuffleDep
}

//接上面的getOrGreateShuffleMapStage函数
createShuffleMapStage(shuffleDep,firstJobId)
->
val stage = new ShuffleMapStage(id,rdd,numTasks,parents,jobId,rdd.creationSite,shuffleDep,...)
//此rdd是当前依赖的rdd，即ShuffleRDD的上一个rdd
val rdd = shuffleDep.rdd

//看上一个rdd有没有shuffle，有的话就再创建一个stage，然后把rdd穿过去再看上一个

//shuffleMapStage执行完毕后写磁盘，然后ResultStage读磁盘
```

<img src="/stage.png" style="zoom:50%;" />

#### 任务的划分

```scala
DAGScheduler.scala
val job = new ActiveJob(jobId,finalStage,...)
...
submitStage(finalStage)
->
getMissingParentStage()
//看看有没有上一级，如果有，则递归调用这个函数
...
//接收任务
val tasks: Seq[Task[_]] = try {
    stage match {
        //如果是ShuffleMapStage
        //计算分区
        partitionsToCompute.map {
            //map，把每一个id变成一个task
            //真正创建task就是在这里，有几个task就返回几个对象
            new ShuffleMapTask(stage.id,stage.latestInfo.attemptNumber,...)
        }
    }
}

partitionsToCompute
->
val partitionsToCompute:Seq[Int] = stage.findMissingPartitions //是一个分区编号集合，如0,1,2
->
ShuffleMapStage.scala
def findMissingPartitions {
    //看看当前shuffleId中有没有这个分区
    //如果有，就取过来
    //如果没有，就是0到partition数量，是一个集合，每一个数字就变成一个task
}
```

stage.png中当前ResultStage有6个task（3+3）

#### 任务的调度



#### 任务的执行

### Shuffle

#### shuffle的原理和执行过程

#### shuffle写磁盘

#### shuffle读磁盘

### 内存管理

#### 内存分类

#### 内存配置