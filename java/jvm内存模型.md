### b站一个讲解

https://www.bilibili.com/video/BV12t411u726/?spm_id_from=trigger_reload

<img src="D:\ideaprojects\School-Notes\Java\pic\object1.png" style="zoom:50%;" />

func11函数运行完毕，栈上内存清空，那堆上内存怎么办？——GC

在堆上创建的内存对象是不能随着函数的运行完毕而自动清理的（因为不知道是否还有其他线程也引用当前这些对象），需要依靠GC

<img src="D:\ideaprojects\School-Notes\Java\pic\object2.png" style="zoom:50%;" />

#### JVM 内存模型总结

（1）JVM 内存模型共分为5个区：Java虚拟机栈、本地方法栈、堆、程序计数器、方法区（元空间）
（2）各个区各自的作用：
	a.本地方法栈：用于管理本地方法的调用，里面并没有我们写的代码逻辑，其由native修饰，由 C 语言实现。
	b.程序计数器：它是一块很小的内存空间，主要用来记录各个线程执行的字节码的地址，例如，分支、循环、线程恢复等都依赖于计数器。
	c.方法区（Java8叫元空间）：用于存放已被虚拟机加载的类信息，常量，静态变量等数据（包括静态函数如main函数）。
	d.Java 虚拟机栈：用于存储局部变量表、操作数栈、动态链接、方法出口等信息。（栈里面存的是地址，实际指向的是堆里面的对象）
	e.堆：Java 虚拟机中内存最大的一块，是被所有线程共享的，几乎所有的对象实例都在这里分配内存；
（3）线程私有、公有
	a.线程私有：每个线程在开辟、运行的过程中会单独创建这样的一份内存，有多少个线程可能有多少个内存
		Java虚拟机栈、本地方法栈、程序计数器是线程私有的
	b.线程全局共享的
		堆和方法区
（4）栈虽然方法运行完毕了之后被清空了，但是堆上面的还没有被清空，所以引出了GC（垃圾回收），不能立马删除，因为不知道是否还有其它的也是引用了当前的地址来访问的

#### 例子A

<img src="D:\ideaprojects\School-Notes\Java\pic\object0.png" style="zoom:80%;" />

本例打印的a是10

<img src="D:\ideaprojects\School-Notes\Java\pic\object0-1.png" style="zoom:80%;" />

#### 例子B

<img src="D:\ideaprojects\School-Notes\Java\pic\object3.png" style="zoom:80%;" />

这种情况输出结果是222

* p2是一个内存地址，指向堆上的一个Person对象（id=111）
* 接下来运行func1函数，func1函数创建一个p副本，p也是一段地址，跟p2地址一样，同样指向同一个Person对象
* 因此修改的是同一个Person对象
* 然后func1运行完毕，p指针被释放