---
typora-root-url: pic
---

Java 虚拟机在执行Java程序的过程中会把它在主存中管理的内存部分划分成多个区域，每个区域存放不同类型的数据。

在这些分区中，占用内存空间最大的一部分叫做 堆 ，也就是我们所说的堆内内存（on-heap memory）。java虚拟机中的堆主要是**存放所有对象的实例**。

这一块区域在java虚拟机启动的时候被创建，被所有的线程所共享，同时也是垃圾收集器的主要工作区域，因此这一部分区域除了被叫做“堆内内存”以外，也被叫做“GC堆”（Garbage Collected Heap）。

<img src="/on-heap-memory.png" style="zoom:55%;" />

#### 堆外内存

为了解决堆内内存过大带来的长时间的GC停顿的问题，以及操作系统对堆内内存不可知的问题，java虚拟机开辟出了堆外内存（off-heap memory）。

堆外内存意味着把一些对象的实例分配在Java虚拟机堆内内存以外的内存区域，这些内存直接受操作系统（而不是虚拟机）管理。

这样做的结果就是能保持一个较小的堆，以减少垃圾收集对应用的影响。同时因为这部分区域直接受操作系统的管理，别的进程和设备（例如GPU）可以直接通过操作系统对其进行访问，减少了从虚拟机中复制内存数据的过程。

java 在NIO 包中提供了ByteBuffer类，对堆外内存进行访问。

```java
import sun.nio.ch.DirectBuffer;

import java.nio.ByteBuffer;

public class TestDirectByteBuffer {
    public static void main(String[] args) throws Exception {
        while (true) {
            ByteBuffer buffer = ByteBuffer.allocateDirect(10 * 1024 * 1024);
        }
    }
}  
```

开辟出10M的堆外内存

**优点 ：**

1. 可以很方便的自主开辟很大的内存空间，对大内存的伸缩性很好
2. 减少垃圾回收带来的系统停顿时间
3. 直接受操作系统控制，可以直接被其他进程和设备访问，减少了原本从虚拟机复制的过程
4. 特别适合那些分配次数少，读写操作很频繁的场景

**缺点 ：**

1. 容易出现内存泄漏，并且很难排查
2. 堆外内存的数据结构不直观，当存储结构复杂的对象时，会浪费大量的时间对其进行串行化。

**与堆内内存联系**

虽然堆外内存本身不受垃圾回收算法的管辖，但是因为其是由ByteBuffer所创造出来的，因此这个buffer自身作为一个实例化的对象，其自身的信息（例如堆外内存在主存中的起始地址等信息）必须存储在堆内内存中，具体情况如下图所示。

<img src="/on-heap-memory2.png" style="zoom:75%;" />

当在堆内内存中存放的buffer对象实例被垃圾回收算法回收掉的时候，这个buffer对应的堆外内存区域同时也就被释放掉了。