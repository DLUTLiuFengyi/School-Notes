### 实例

#### 统计每个省份每个广告被点击数量排行的top3

```scala
//1.获取原始数据：时间戳 省份 城市 用户 广告
val dataRDD = sc.textFile("datas/agent.log")
//2.结构转换
//   （（省份，广告），1）
val mapRDD = dataRDD.map(
	line => {
        val data = line.split(" ")
        ((data(1),data(4)),1)
    }
)
//3.将转换结构后的数据进行分组聚合
//   （（省份，广告），sum）
//分组+聚合，用reduceByKey
val reduceRDD: RDD[((String,String),Int)] = mapRDD.reduceByKey(_+_) //两两聚合
//4.结构转换
//   （省份，（广告，sum））
val newMapRDD = reduceRDD.map{
    case ((prv,ad),sum) => {
        (prv,(ad,sum))
    }
}
//5.根据省份分组
//   （省份，【（广告A，sumA），（广告B，sumB）】）
val groupRDD:RDD[(String,Iterable[(String,Int)])] = newMapRDD.groupByKey()
//6.将分组后的数据组内排序（降序），取前三名
//可迭代集合不能排序，需要先转换成List
val resultRDD = groupRDD.mapValues(
	iter => {
        iter.toList.sortBy(_._2)(ordering.Int.reverse).take(3)
    }
)
//7.采集数据打印在控制台
resultRDD.collect().foreach(println)
```

#### WordCount

85集

### 案例实操

https://www.bilibili.com/video/BV11A411L7CK?p=115&spm_id_from=pageDriver

110集