https://www.cnblogs.com/schoolbag/p/9640990.html

## 主要区别：

map是对rdd中的每一个元素进行操作；

mapPartitions则是对rdd中的每个分区的迭代器进行操作

## MapPartitions的优点：

如果是普通的map，比如一个partition中有1万条数据。ok，那么你的function要执行和计算1万次。

使用MapPartitions操作之后，一个task仅仅会执行一次function，function一次接收所有
的partition数据。只要执行一次就可以了，性能比较高。如果在map过程中需要频繁创建额外的对象(例如将rdd中的数据通过jdbc写入数据库,map需要为每个元素创建一个链接而mapPartition为每个partition创建一个链接),则mapPartitions效率比map高的多。

SparkSql或DataFrame默认会对程序进行mapPartition的优化。

## MapPartitions的缺点：

如果是普通的map操作，一次function的执行就处理一条数据；那么如果内存不够用的情况下， 比如处理了1千条数据了，那么这个时候内存不够了，那么就可以将已经处理完的1千条数据从内存里面垃圾回收掉，或者用其他方法，腾出空间来吧。
所以说普通的map操作通常不会导致内存的OOM异常。 

但是MapPartitions操作，对于大量数据来说，比如甚至一个partition，100万数据，
一次传入一个function以后，那么可能一下子内存不够，但是又没有办法去腾出内存空间来，可能就OOM，内存溢出。

```scala
def main(args: Array[String]): Unit = {

  var conf = new SparkConf().setMaster("local[*]").setAppName("partitions")
  var sc   = new SparkContext(conf)

  println("1.map--------------------------------")
  var aa   = sc.parallelize(1 to 9, 3)
  def doubleMap(a:Int) : (Int, Int) = { (a, a*2) }
  val aa_res = aa.map(doubleMap)
  println(aa.getNumPartitions)
  println(aa_res.collect().mkString)

  
  println("2.mapPartitions-------------------")
  val bb = sc.parallelize(1 to 9, 3)
  def doubleMapPartition( iter : Iterator[Int]) : Iterator[ (Int, Int) ] = {
    var res = List[(Int,Int)]()
    while (iter.hasNext){
      val cur = iter.next()
      res .::= (cur, cur*2)
    }
    res.iterator
  }
  val bb_res = bb.mapPartitions(doubleMapPartition)
  println(bb_res.collect().mkString)


  println("3.mapPartitions-------------------")
  var cc = sc.makeRDD(1 to 5, 2)
  var cc_ref = cc.mapPartitions( x => {
    var result = List[Int]()
    var i = 0
    while(x.hasNext){
      val cur = x.next()
      result.::= (cur*2)
    }
    result.iterator
  })
  cc_ref.foreach(println)
}
```

```txt
1.map--------------------------------
3
(1,2)(2,4)(3,6)(4,8)(5,10)(6,12)(7,14)(8,16)(9,18)

2.mapPartitions-------------------
(3,6)(2,4)(1,2)(6,12)(5,10)(4,8)(9,18)(8,16)(7,14)

3.mapPartitions-------------------
4
2
10
8
6
```

