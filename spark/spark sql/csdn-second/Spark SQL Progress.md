---
typora-root-url: pic
---

## Spark SQL Progress

![](/sparksqlprogress1.png)

![](/sparksqlprogress2.png)

* sql
* sql parser(parse) 生成 unresolved logical plan
* analyzer(analysis) 生成 analyzed logical plan
* optimizer(optimize) 生成 optimized logical plan
* spark planner(use strategies to plan) 生成 physical plan
* 采用不同Strategies 生成 spark plan
* spark plan(prepare) 生成 prepared spark plan
* call toRDD (execute() 函数调用) 执行sql生成RDD

### Parse SQL

```scala
/**
   * Executes a SQL query using Spark, returning the result as a SchemaRDD.
   *
   * @group userf
   */
   def sql(sqlText: String): SchemaRDD = new SchemaRDD(this, parseSql(sqlText))
```

here the result of **parseSql** is a logical plan

```scala
@transient
  protected[sql] val parser = new catalyst.SqlParser  
 
  protected[sql] def parseSql(sql: String): LogicalPlan = parser(sql)
```

### Analyze to Execution

when we call `collect` in **SchemaRDD**, will initiate **QueryExecution**

```scala
override def collect(): Array[Row] = queryExecution.executedPlan.executeCollect()
```

```scala

protected abstract class QueryExecution {
    def logical: LogicalPlan
 
    lazy val analyzed = analyzer(logical)  //首先分析器会分析逻辑计划
    lazy val optimizedPlan = optimizer(analyzed) //随后优化器去优化分析后的逻辑计划
    // TODO: Don't just pick the first one...
    lazy val sparkPlan = planner(optimizedPlan).next() //根据策略生成plan物理计划
    // executedPlan should not be used to initialize any SparkPlan. It should be
    // only used for execution.
    lazy val executedPlan: SparkPlan = prepareForExecution(sparkPlan) //最后生成已经准备好的Spark Plan
 
    /** Internal version of the RDD. Avoids copies and has no schema */
    lazy val toRdd: RDD[Row] = executedPlan.execute() //最后调用toRDD方法执行任务将结果转换为RDD
 
    protected def stringOrError[A](f: => A): String =
      try f.toString catch { case e: Throwable => e.toString }
 
    def simpleString: String = stringOrError(executedPlan)
 
    override def toString: String =
      s"""== Logical Plan ==
         |${stringOrError(analyzed)}
         |== Optimized Logical Plan ==
         |${stringOrError(optimizedPlan)}
         |== Physical Plan ==
         |${stringOrError(executedPlan)}
      """.stripMargin.trim
  }
```

