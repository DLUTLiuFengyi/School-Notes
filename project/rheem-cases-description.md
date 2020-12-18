#### PageRank

##### 知乎粉丝数据集 60MB

节点数 459199   边数 4612110

```shell
java -jar pagerank.jar "basic-graph,java,java-conversion,java-graph,spark,spark-graph,graphchi" "file:/nfs/data/datasets/graph_test_dqh/dqh_graph_test.csv" 32
```

用时18s



##### LiveJournal social network 1.06GB

节点数 4847571   边数 68993773

```shell
java -jar pagerank_soc_case.jar "basic-graph,java,java-conversion,java-graph,graphchi" "file:/nfs/data/datasets/pagerank_soc_LiveJournal.txt" 1
```

迭代10次，用时207s