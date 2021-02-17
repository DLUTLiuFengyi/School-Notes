---
typora-root-url: pic
---

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



#### Driver => Executor

#### Executor => Driver

#### Executor => Executor





### 应用程序的执行

#### RDD依赖

#### 阶段的划分

#### 任务的划分

#### 任务的调度

#### 任务的执行

### Shuffle

#### shuffle的原理和执行过程

#### shuffle写磁盘

#### shuffle读磁盘

### 内存管理

#### 内存分类

#### 内存配置