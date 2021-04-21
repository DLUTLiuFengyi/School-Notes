### 锁分类

悲观锁

先上锁，再做事

* 共享锁 读锁
* 排他锁 写锁

乐观锁

先做事，在提交前进行冲突检测

* CAS Compare and swap

  使用原子变量实现

* 版本号控制



### 数据结构

ConcurrentHashMap

LinkedBlockingQueue

ArrayBlockingQueue

