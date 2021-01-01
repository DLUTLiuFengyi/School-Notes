#### Spark Properties

```properties
spark.master = spark://10.176.24.160:8077
spark.app.name = Rheem PageRank soc App
spark.ui.showConsoleProgress = false
spark.driver.memory = 24g
spark.executor.memory = 108g
spark.driver.maxResultSize=24g

rheem.spark.cpu.mhz = 2700
rheem.spark.machines = 2
rheem.spark.cores-per-machine = 56
```



#### WordCount

##### "The great Gatsby" excerpts

**java**

```shell
java -jar wordcount.jar "java,spark" "file:/nfs/data/datasets/wordcount_50G.txt" "/home/lfy/results/wordcount_result.txt"
```

**spark**

```shell
./spark-submit --class com.github.dlut.pagerank.scala.PageRank  ~/jars/wordcount.jar "java,spark" "file:/home/lfy/data/wordcount_50G.txt" "/home/lfy/results/wordcount_result.txt"
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

