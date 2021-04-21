---
typora-root-url: pic
---

## Prepare for Execution

Change the Physical Plan into executable Physical Plan.

some prepared work: insert some `shuffle` work, transfer some data format ...

```scala
class QueryExecution(val sparkSession: SparkSession, val logical: LogicalPlan) {
  ......其他代码
  lazy val executedPlan: SparkPlan = prepareForExecution(sparkPlan)
  
  //调用下面的preparations，然后使用foldLeft遍历preparations中的Rule并应用到SparkPlan
  protected def prepareForExecution(plan: SparkPlan): SparkPlan = {
    preparations.foldLeft(plan) { case (sp, rule) => rule.apply(sp) }
  }

  /** A sequence of rules that will be applied in order to the physical plan before execution. */
  //定义各个Rule
  protected def preparations: Seq[Rule[SparkPlan]] = Seq(
    PlanSubqueries(sparkSession),
    EnsureRequirements(sparkSession.sessionState.conf),
    CollapseCodegenStages(sparkSession.sessionState.conf),
    ReuseExchange(sparkSession.sessionState.conf),
    ReuseSubquery(sparkSession.sessionState.conf))
  ......其他代码
}
```

**PlanSubqueries(sparkSession)**

generate sub query , that is to generate a new **QueryExecution** (recursively). note that variables in QE are lazy load, so they will be not exe immediately, and exe at last together

**EnsureRequirements(sparkSession.sessionState.conf)**

verify whether the output partitions are the same as waht we need, if not, add `shuffle` to progress re-partition, and need to sort sometimes

**CollapseCodegenStages**

about optimization. change a series of **operators** into a piece of code (spark sql to java code) to improve performance

![](/prepare1.png)

**ReuseExchange and ReuseSubquery**

Exchange defines `shuffle`, ReuseExchange finds repeated Exchange and avoids repeated computation

ReuseSubquery avoids repeated sub query

#### example 

```scala
//生成DataFrame
val df = Seq((1, 1)).toDF("key", "value")
df.createOrReplaceTempView("src")
//调用spark.sql
val queryCaseWhen = sql("select key from src ")
```

after preparation

```scala
Project [_1#2 AS key#5]
+- LocalTableScan [_1#2, _2#3]
```

好吧这里看还是和之前Optimation阶段一样，不过断点看就不大一样了。

![](/prepare2.png)

due to the simple SQL, here just adds two **SparkPlan**: WholeStageCodegenExec and InputAdapter



## Execution

```scala
class QueryExecution(val sparkSession: SparkSession, val logical: LogicalPlan) {
  ......其他代码
  lazy val toRdd: RDD[InternalRow] = executedPlan.execute()
  ......其他代码
}
```

SparkPlan.execute()   ->   doExecute() [each sub class implements]

now we discuss the doExecute() in **ProjectExec** and **LocalTableScanExec**

```scala
case class ProjectExec(projectList: Seq[NamedExpression], child: SparkPlan)
  extends UnaryExecNode with CodegenSupport {
   ......其他代码
  protected override def doExecute(): RDD[InternalRow] = {
    child.execute().mapPartitionsWithIndexInternal { (index, iter) =>
      val project = UnsafeProjection.create(projectList, child.output,
        subexpressionEliminationEnabled)
      project.initialize(index)
      iter.map(project)
    }
  }
  ......其他代码
}
```

it first recursively calls the **doExecute()** of child (**LocalTableScanExec**)

```scala
case class LocalTableScanExec(
    output: Seq[Attribute],
    @transient rows: Seq[InternalRow]) extends LeafExecNode {
  ......其他代码
	
  private lazy val rdd = sqlContext.sparkContext.parallelize(unsafeRows, numParallelism)
  
  protected override def doExecute(): RDD[InternalRow] = {
    val numOutputRows = longMetric("numOutputRows") // just a measurement
    rdd.map { r =>
      numOutputRows += 1
      r
    }
  }
	
  ......其他代码
```

child.execute().mapPartitionsWithIndexInternal 

```scala
child.execute().mapPartitionsWithIndexInternal { (index, iter) =>
  val project = UnsafeProjection.create(projectList, child.output,
    subexpressionEliminationEnabled)
  project.initialize(index)
  iter.map(project) // iter.map(i=>project.apply(i)) progress each line of data
}
```

the implement of project is **interpretedUnsafeProjection**

```scala
class InterpretedUnsafeProjection(expressions: Array[Expression]) extends UnsafeProjection {
  ......其他代码
  override def apply(row: InternalRow): UnsafeRow = {
    // Put the expression results in the intermediate row.
    var i = 0
    while (i < numFields) {
      values(i) = expressions(i).eval(row)
      i += 1
    }

    // Write the intermediate row to an unsafe row.
    rowWriter.reset()
    writer(intermediate)
    rowWriter.getRow()
  }
  
  ......其他代码
```

the last three lines, write the result into `result row`, and return. when exe over, can get the last **RDD[internalRow]**