### Rheem  on non-k8s

#### Java Properties

```properties
rheem.java.cores = 56
```

#### Spark Properties

```properties
spark.master = spark://ip:8077
#spark.master = spark://spark-master-svc:7077 #k8s
spark.app.name = Rheem App
spark.ui.showConsoleProgress = false
spark.driver.memory = 50g
spark.executor.memory = 120g
spark.driver.maxResultSize=10g

rheem.spark.cpu.mhz = 2700
rheem.spark.machines = 3
rheem.spark.cores-per-machine = 62
```

java.net.URISyntaxException: Illegal character in authority at index 8: spark://ip:8077

原因：spark://ip:8077后多了一个空格



#### WordCount

##### "The great Gatsby" excerpts

**java**

```shell
java -jar ~/jars/wordcount.jar "java" "file:/home/lfy/data/wordcount_1G.txt" "/home/lfy/results/wordcount_result.txt"
```

**spark**

```shell
./spark-submit --class com.github.dlut.wordcount.java.WordCount ~/jars/wordcount.jar "java,spark" "file:/home/lfy/data/wordcount_1G.txt" "/home/lfy/results/wordcount_result.txt"
```



#### PageRank

##### 知乎粉丝数据集 60MB

节点数 459199   边数 4612110

**java**

迭代32次，用时18s，近似收敛

```shell
java -jar pagerank.jar "basic-graph,java,java-conversion,java-graph,graphchi" "file:/nfs/data/datasets/graph_test_dqh/dqh_graph_test.csv" 32 "/nfs/data/lfy/results/pagerank_result.txt"
```

**spark**

迭代32次，用时107.87s，近似收敛

```shell
./spark-submit --class com.github.dlut.pagerank.scala.PageRank  ~/jars/pagerank.jar "basic-graph,java,java-conversion,java-graph,spark,spark-graph,graphchi" "file:/home/lfy/data/dqh_graph_test.csv" 32 "/home/lfy/results/pagerank_result.txt"
```



##### Stanford LiveJournal social network 1.06GB

节点数 4847571   边数 68993773

**java**

迭代10次，用时207s

迭代15次，用时256.13s，近似收敛

```shell
java -jar pagerank_soc.jar "basic-graph,java,java-conversion,java-graph,graphchi" "file:/nfs/data/datasets/pagerank_soc_LiveJournal.txt" 10 "/nfs/data/lfy/results/pagerank_result.txt"
```

**spark**

迭代15次，用时196.7s

```shell
./spark-submit --class com.github.dlut.pagerank.scala.PageRank  ~/jars/pagerank_soc.jar "basic-graph,java,java-conversion,java-graph,spark,spark-graph,graphchi" "file:/home/lfy/data/pagerank_soc_LiveJournal.txt" 15 "/home/lfy/results/pagerank_result.txt"
```



---

### CLIC

```shell
java -jar .\wc_java.jar --udfPath=D:/2020project/data/udfs/WordCountUDF.class --dagPath=D:/2020project/data/yaml/physical-dag-212742111.yml

java -jar ~/jars/wc_java.jar --udfPath=/home/lfy/data/WordCountUDF.class --dagPath=/home/lfy/codes/yaml/physical-dag-wc-java-local-1g.yml

./spark-submit --master=spark://ip:8077 --class fdu.daslab.executable.spark.ExecuteSparkOperator ~/jars/wc_spark.jar --udfPath=/home/lfy/data/WordCountUDF.class --dagPath=/home/lfy/codes/yaml/physical-dag-wc-spark-local-1g.yml
```



---

### HDFS

```shell
hdfs dfs -ls \

# 创建文件夹
hdfs dfs -mkdir /data/datasets/wordcount
# 上传
hdfs dfs -put ~/data/wordcount_1G.txt /data/datasets/wordcount
# 下载
hdfs dfs -get /data/datasets/wordcount/wordcount_1G.txt ~/results

String hdfsPath = "hdfs://ip:port/data/datasets/wordcount/wordcount_1G.txt"
```

https://www.jianshu.com/p/52506c7bf662



---

#### London crime

```shell
java -Xmx50g -jar london.jar java hdfs://ip:9820/tzw/london_crime/london_crime_0.45g.csv

./spark-submit --class com.github.dlut.london.SparkJavaTask ~/jars/london.jar "spark" hdfs://ip:9820/tzw/london_crime/london_crime_0.45g.csv

# 考虑java平台时，需要特别声明--driver-memory，以避免堆溢出
# 此参数等同于java里的-Xmx，含义是最大堆大小
./spark-submit --driver-memory 50G --class com.github.dlut.london.SparkJavaTask ~/jars/london.jar "java" hdfs://ip:9820/tzw/london_crime/london_crime_3.5g.csv
```

我们使用java -X可以看到java的-X系列的参数

* Xmx: memory max

  最大可以从操作系统中获取的内存数量

* Xms: memory start

  程序启动的时候从操作系统中获取的内存数量

`java -cp . -Xms80m -Xmx256m `

说明这个程序启动的时候使用80m的内存，最多可以从操作系统中获取256m的内存



| 数据量 | spark  | java   | spark + java |
| ------ | ------ | ------ | ------------ |
| 450M   | 24068  | 7985   | 7848         |
| 900M   | 24593  | 13169  | 13495        |
| 1.8G   | 24967  | 25666  | 24906        |
| 3.5G   | 26782  | 46158  | 46673        |
| 7G     | 28500  | 92170  | 97834        |
| 14G    | 39989  | 185162 | 187278       |
| 28G    | 155150 | 360084 | 366560       |

| 数据量 | spark | java | spark + java |
| ------ | ----- | ---- | ------------ |
| 450M   |       |      |              |
| 900M   |       |      |              |
| 1.8G   |       |      |              |
| 3.5G   |       |      |              |
| 7G     | 27963 |      |              |
| 14G    | 33548 |      |              |
| 28G    |       |      | 361229       |

**结论**

* spark+java的情况，选择java平台

* java没有开启并行，所以慢

相同时间段内（12:00am-12:30am），7G的实验结果是28500~98900，14G的实验结果是39989~122000，波动特别大。大概率与160机子的状态不正常有关。

7G结果为28500与14G结果为39989时，spark的worker甚至只需要161、162两台即可。

因此接下来将尝试将数据源从HDFS转换为161、162本地存储。

### Spark UI of Rheem

**结论**

绝大部分时间花在SparkSortOperator.java这个类，占87.5%

具体为

job 0 中 stage 0的sorByKey at SparkSortOperator.java:70 占43.75%

job 1 中 stage 1的mapToPair at SparkSortOperator.java:68 占43.75%



对这个workflow，不论数据量多大，rheem均将其划分成0到336共337个job，0到1008共1009个stage.

其中job 0包含1个stage，job 1到336分别包含3个stage，job 1到336包含的3个stage任务都相同

其中job 1的3个stage均是completed，job 2到336的3个stage里有1个是completed，2个是skipped

**job 0**

Description: 

sortByKey at SparkSortOperator.java:70

Duration:

1.4min

**job 1-336**

Description: 

hasNext at Iterator.java:132

Duration: 

12-35ms, 其中job 1用时1.5min，特别长

**job 1**

均为completed stage

stage3 hasNext at Iterator.java:132 61ms

stage2 mapToPair at SparkReduceByOperator.java:73 8s

stage1 mapToPair at SparkSortOperator.java:68 1.4min

**job i, 2<=i<=336**

1个completed stage

stage i*3 hasNext at Iterator.java:132

2个skipped stage

stage i*3-1 mapToPair at SparkReduceByOperator.java:73

stage i*3-2 mapToPair at SparkSortOperator.java:68

部分job有其DAG图，

stage i*3-2 是 

textFile -> map -> map -> filter -> map

 stage i*3-1 是 

sortByKey -> map -> map -> map

stage i*3 是 

reduceByKey -> map 

详细DAG

reduceByKey   ReduceByKey [12] reduceByKey at SparkReduceByOperator.java:76

到

map   ReduceByKey [13] map at SparkReduceByOperator.java:78





