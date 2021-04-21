## SparkPlan

Transfer the Logical Plan into Physical Plan

A `SparkPlan` physical operator is a [Catalyst tree node](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/content/spark-sql-catalyst-TreeNode.html) that may have zero or more [child physical operators](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/content/spark-sql-catalyst-TreeNode.html#children).

The entry point to **Physical Operator Execution Pipeline** is [execute](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/content/spark-sql-SparkPlan.html#execute).

The result of [executing](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/content/spark-sql-SparkPlan.html#execute) a `SparkPlan` is an `RDD` of [internal binary rows](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/content/spark-sql-InternalRow.html), i.e. `RDD[InternalRow]`.

#### SparkPlan's final methods

* execute
* executeQuery
* prepare

#### physical query operators / specialized SparkPlans

* BinaryExecNode

  Binary physical operator with two child `left` and `right` physical operators.

* LeafExecNode

  Leaf physical operator with no children

  By default, the [set of all attributes that are produced](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/content/spark-sql-catalyst-QueryPlan.html#producedAttributes) is exactly the [set of attributes that are output](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/content/spark-sql-catalyst-QueryPlan.html#outputSet).

* UnaryExecNode

  Unary physical operator with one `child` physical operator.



## A Blog

Scheduling in QueryExecution

```scala
class QueryExecution(val sparkSession: SparkSession, val logical: LogicalPlan) {
  ......其他代码
  lazy val sparkPlan: SparkPlan = {
    SparkSession.setActiveSession(sparkSession)
    // TODO: We use next(), i.e. take the first plan returned by the planner, here for now,
    //       but we will implement to choose the best plan.
    planner.plan(ReturnAnswer(optimizedPlan)).next()
  }
  ......其他代码
}
```

the class of `planner` here is **SparkPlanner**, this class extends **QueryPlanner**, and SparkPlanner's `plan()` is implemented in QueryPlanner. Similar with RuleExecution, there is a method called `def strategies` that return `Seq[GenericStrategy[PhysicalPlan]]` in **QueryPlanner**, this method is override in **SparkPlanner**, and is called by QueryPlanner's `plan()`

the `def strategies` in SparkPlanner

```scala
class SparkPlanner(
    val sparkContext: SparkContext,
    val conf: SQLConf,
    val experimentalMethods: ExperimentalMethods)
  extends SparkStrategies {
  ......其他代码
  override def strategies: Seq[Strategy] =
    experimentalMethods.extraStrategies ++
      extraPlanningStrategies ++ (
      PythonEvals ::
      DataSourceV2Strategy ::
      FileSourceStrategy ::
      DataSourceStrategy(conf) ::
      SpecialLimits ::
      Aggregation ::
      Window ::
      JoinSelection ::
      InMemoryScans ::
      BasicOperators :: Nil)
	......其他代码
	
```

strategies()返回策略列表，是生成策略GenericStrategy，这是个具体的抽象类，位于org.apache.spark.sql.catalyst.planning包。所谓生成策略，就是决定如果根据Logical Plan生成Physical Plan的策略。比如上面介绍的join操作可以生成Broadcast join，Hash join，抑或是MergeSort join，就是一种生成策略，具体的类就是上面代码中的JoinSelection。每个生成策略GenericStrategy都是object，其apply()方法返回的是Seq[SparkPlan]，**这里的SparkPlan就是PhysicalPlan**（注意：下文会将SparkPlan和PhysicalPlan混着用）。

the `plan()` in QueryPlanner

```scala
abstract class QueryPlanner[PhysicalPlan <: TreeNode[PhysicalPlan]] {
  ......其他代码
  def plan(plan: LogicalPlan): Iterator[PhysicalPlan] = {
    // Obviously a lot to do here still...

    // Collect physical plan candidates.
    val candidates = strategies.iterator.flatMap(_(plan))	//迭代调用并平铺，变成Iterator[SparkPlan]

    // The candidates may contain placeholders marked as [[planLater]],
    // so try to replace them by their child plans.
    val plans = candidates.flatMap { candidate =>
      val placeholders = collectPlaceholders(candidate)

      if (placeholders.isEmpty) {
        // Take the candidate as is because it does not contain placeholders.
        Iterator(candidate)
      } else {
        // Plan the logical plan marked as [[planLater]] and replace the placeholders.
        placeholders.iterator.foldLeft(Iterator(candidate)) {
          case (candidatesWithPlaceholders, (placeholder, logicalPlan)) =>
            // Plan the logical plan for the placeholder.
            val childPlans = this.plan(logicalPlan)	

            candidatesWithPlaceholders.flatMap { candidateWithPlaceholders =>
              childPlans.map { childPlan =>
                // Replace the placeholder by the child plan
                candidateWithPlaceholders.transformUp {
                  case p if p.eq(placeholder) => childPlan
                }
              }
            }
        }
      }
    }

    val pruned = prunePlans(plans)
    assert(pruned.hasNext, s"No plan for $plan")
    pruned
  }
  
  ......其他代码
}
```

the progress above is calling the `apply()` of each kind of GenericStrategy, generating `Iterator[SparkPlan]`. each SparkPlan is executable physical operation 

example code: 

```scala
//生成DataFrame
val df = Seq((1, 1)).toDF("key", "value")
df.createOrReplaceTempView("src")
//调用spark.sql
val queryCaseWhen = sql("select key from src ")
```

after Physical Planning

```scala
Project [_1#2 AS key#5]
+- LocalTableScan [_1#2, _2#3]
```

comparing with optimization phase, the **LocalRelation** changes to **LocalTableScan**