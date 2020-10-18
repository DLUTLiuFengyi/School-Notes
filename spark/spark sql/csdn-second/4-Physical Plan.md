## Physical Plan

the last plan in **Catalyst**

![](D:\ideaprojects\yanjiushengbiji\spark\spark sql\csdn-second\physicalplan1.png)

### SparkPlanner

```scala
lazy val optimizedPlan = optimizer(analyzed)
// TODO: Don't just pick the first one...
lazy val sparkPlan = planner(optimizedPlan).next()
```

the `apply` method of **SparkPlanner** will return a **Iterator[Physical]**

SparkPlanner extends SparkStrategies, SparkStrategies extends QueryPlanner

**SparkStrategies** includes a series of **Strategies**, those Str..s extend Strategy in **QueryPlanner**, it receives a **Logical Plan**, generates a series of **Physical Plan** 

```scala
  @transient
  protected[sql] val planner = new SparkPlanner
  
    protected[sql] class SparkPlanner extends SparkStrategies {
    val sparkContext: SparkContext = self.sparkContext
 
    val sqlContext: SQLContext = self
 
    def numPartitions = self.numShufflePartitions //partitions的个数
 
    val strategies: Seq[Strategy] =  //策略的集合
      CommandStrategy(self) ::
      TakeOrdered ::
      PartialAggregation ::
      LeftSemiJoin ::
      HashJoin ::
      InMemoryScans ::
      ParquetOperations ::
      BasicOperators ::
      CartesianProduct ::
      BroadcastNestedLoopJoin :: Nil
	 etc......
	 }
```

QueryPlanner, defines Strategy, planLater, apply ...

```scala
abstract class QueryPlanner[PhysicalPlan <: TreeNode[PhysicalPlan]] {
  /** A list of execution strategies that can be used by the planner */
  def strategies: Seq[Strategy]
 
  /**
   * Given a [[plans.logical.LogicalPlan LogicalPlan]], returns a list of `PhysicalPlan`s that can
   * be used for execution. If this strategy does not apply to the give logical operation then an
   * empty list should be returned.
   */
  abstract protected class Strategy extends Logging {
    def apply(plan: LogicalPlan): Seq[PhysicalPlan]  //接受一个logical plan，返回Seq[PhysicalPlan]
  }
 
  /**
   * Returns a placeholder for a physical plan that executes `plan`. This placeholder will be
   * filled in automatically by the QueryPlanner using the other execution strategies that are
   * available.
   */
  protected def planLater(plan: LogicalPlan) = apply(plan).next() //返回一个占位符，占位符会自动被QueryPlanner用其它的strategies apply
 
  def apply(plan: LogicalPlan): Iterator[PhysicalPlan] = {
    // Obviously a lot to do here still...
    val iter = strategies.view.flatMap(_(plan)).toIterator //整合所有的Strategy，_(plan)每个Strategy应用plan上，得到所有Strategies执行完后生成的所有Physical Plan的集合，一个iter
    assert(iter.hasNext, s"No plan for $plan")
    iter //返回所有物理计划
  }
}
```

![](D:\ideaprojects\yanjiushengbiji\spark\spark sql\csdn-second\physicalplan2.png)

### Spark Plan

Spark Plan is the abstract class in **Catalyst** that the **physical execute plan** going though all **Strategies apply** 

```scala
lazy val executedPlan: SparkPlan = prepareForExecution(sparkPlan)
```

prepareForExecution is a **RuleExecutor[SparkPlan]**, the rule here is SparkPlan

```scala
@transient
  protected[sql] val prepareForExecution = new RuleExecutor[SparkPlan] {
    val batches =
      Batch("Add exchange", Once, AddExchange(self)) :: //添加shuffler操作如果必要的话
      Batch("Prepare Expressions", Once, new BindReferences[SparkPlan]) :: Nil //Bind references
  }
```

 Spark Plan extends Query Plan[Spark Plan], inside defines partition, requiredChildDistribution and the execute method of spark sql

```scala
abstract class SparkPlan extends QueryPlan[SparkPlan] with Logging {
  self: Product =>
 
  // TODO: Move to `DistributedPlan`
  /** Specifies how data is partitioned across different nodes in the cluster. */
  def outputPartitioning: Partitioning = UnknownPartitioning(0) // TODO: WRONG WIDTH!
  /** Specifies any partition requirements on the input data for this operator. */
  def requiredChildDistribution: Seq[Distribution] =
    Seq.fill(children.size)(UnspecifiedDistribution)
 
  /**
   * Runs this query returning the result as an RDD.
   */
  def execute(): RDD[Row]  //真正执行查询的方法execute，返回的是一个RDD
 
  /**
   * Runs this query returning the result as an array.
   */
  def executeCollect(): Array[Row] = execute().map(_.copy()).collect() //exe & collect
 
  protected def buildRow(values: Seq[Any]): Row =  //根据当前的值，生成Row对象，其实是一个封装了Array的对象。
    new GenericRow(values.toArray)
}
```

![](D:\ideaprojects\yanjiushengbiji\spark\spark sql\csdn-second\physicalplan3.png)

### Execution

Spark Plan的Execution方式均为调用其execute()方法生成RDD，除了简单的基本操作例如上面的basic operator实现比较简单，其它的实现都比较复杂，大致的实现我都在上面介绍了，本文就不详细讨论了。

### Conclution

Optimized Logical Plan   ->   Spark Plan

during this process, using many **Strategies**, each Strategies is executed in **RuleExecutor**, in the end generates a series of **Executed Spark Plans**

after generating Executed Spark Plans, can call `collect()` to start **Spark Job** to get on real **Spark SQL**