### 机器学习实时化

* 特征工程

* 样本工程

* 模型训练

  增量训练、实时更新

<img src="D:\ideaprojects\School-Notes\Flink\pic\ai1.png" style="zoom:45%;" />

### ai实时化与流批一体的联系

<img src="D:\ideaprojects\School-Notes\Flink\pic\ai2.png" style="zoom:45%;" />Phi 架构：一个引擎处理所有数据

一个引擎同时做批和流的训练

流批分别都需要做迭代语义，做同一，可以流批互相切换

<img src="D:\ideaprojects\School-Notes\Flink\pic\ai3.png" style="zoom:50%;" />

绿色是流作业，蓝色是批作业

流批都可以用一个引擎flink处理

流作业是不会跑完的

store存储部分也需要做流批一体（后续）

传统：基于作业状态的调度

在线：基于事件驱动的调度

一些事件触发某些条件后就能进行调度，而不需要等上一个作业做完，调度会触发action（启动作业、重启作业、停止作业）

<img src="D:\ideaprojects\School-Notes\Flink\pic\ai5.png" style="zoom:70%;" />

data edge：数据的依赖关系

control edge：一个节点的运行依赖于上游节点有些事件的触发

<img src="D:\ideaprojects\School-Notes\Flink\pic\ai6.png" style="zoom:70%;" />

translator：将用户定义好的ai graph翻译成调度器认识的workflow

第一步：tr根据ai graph控制边分解成三个子图，内部只有数据依赖边

<img src="D:\ideaprojects\School-Notes\Flink\pic\ai7.png" style="zoom:67%;" />

### notification service

监听-收到-更新

<img src="D:\ideaprojects\School-Notes\Flink\pic\ai8.png" style="zoom:67%;" />

dagtrigger：发现哪些air flow需要被调度

executor：具体执行哪些作业的调度，会启动具体的作业job运行实例，然后接受notification service通知，job通知ns后，ns通知exe有新事件发生了，exe执行新的调度

job：产生事件，发送给n s

notification service：负责对事件监听转发

### 事件触发模式

#### 批触发流任务

<img src="D:\ideaprojects\School-Notes\Flink\pic\ai9.png" style="zoom:67%;" />