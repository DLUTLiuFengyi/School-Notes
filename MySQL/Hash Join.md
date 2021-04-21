---
typora-root-url: pic
---

### Hash join in MySQL 8

https://mysqlserverteam.com/hash-join-in-mysql-8/#:~:text=Hash%20join%20is%20a%20way,inputs%20can%20fit%20in%20memory.

两个阶段：build phase，probe phase

#### 若内存中装不下build input

当在build phase中内存满时，server会将build input剩下部分写到外面的磁盘上，写成几个chunk files。

server会设置chunks的数量为合适的数值，以保证最大的chunk也能被单独保存在内存中。注意MySQL中每个input的chunk files数量最大值为128。

一行row会被写到哪个chunk file由join key的hash计算结果决定（hash_2）。注意对要写进chunk file的join key进行的hash函数与之前写进内存的build input所用的hash函数（hash）不一样。

<img src="/build-phase-on-disk-1.jpg" style="zoom:75%;" />

在probe phase时，server先对内存中的hash表的匹配rows进行探测。

一行row也可能匹配被写在磁盘中的rows，因此来自probe input的每一行也被写进a set of chunk files中。

一行row会被写进哪一个chunk file由跟build input写进磁盘时使用的相同的hash函数和公式决定（hash_2）。通过这个方法，我们保证两个input之间的matching rows会被定位到相同的pair of chunk files.

<img src="/probe-phase-on-disk.jpg" style="zoom:75%;" />

当probe phase结束时，我们开始从磁盘中读取chunk files。

通常server做一个build and probe phase时使用第一个set of chunk files作为build and probe input。我们从build input中加载第一个chunk file到内存hash表中（因此前面需要保证最大的chunk file也要能放进内存中）。

Build chunk加载完后，我们从probe input中读对应的chunk file，并探测内存hash表里的匹配项，就像普通情况（everything fits in memory）。

当第一对chunk files被处理完，我们移到下一对chunk files，继续直到所有pairs of chunk files被处理完。

<img src="/build-and-probe-with-chunk-files-1.jpg" style="zoom:75%;" />

当给rows分区时，写到外面的chunk files（hash_2）与写进内存中的hash表所用的hash函数（hash）是不一样的。

如果我们对两种操作都使用相同的hash函数，我们在加载一个build chunk file进hash表时，会得到一个相当bad的hash表，因为相同chunk file中的所有rows会hash到相同的值。