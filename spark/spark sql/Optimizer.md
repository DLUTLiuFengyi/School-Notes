---
typora-root-url: pic
---

## Optimizer

There are two parts of optimization in spark sql, the first is this step. It's **rule-base**.

(The other optimization is called **cost-base**, happening in **Physical Plan**)

we can define our own optimized rule

```scala
object DecimalAggregates extends Rule[LogicalPlan] {
  /** Maximum number of decimal digits in a Long */
  val MAX_LONG_DIGITS = 18
  def apply(plan: LogicalPlan): LogicalPlan = {
    plan transformAllExpressions {
      case Sum(e @ DecimalType.Expression(prec , scale))
        if prec + 10 <= MAX_LONG_DIGITS =>
          MakeDecimal(Sum(UnscaledValue(e)), prec + 10, scale)
  }
}
```

the example code: 

```scala
val df = Seq((1, 1)).toDF("key", "value")
df.createOrReplaceTempView("src")
val queryCaseWhen = sql("select key from src")
```

after optimization: 

```shell
Project [_1#2 AS key#5]
+- LocalRelation [_1#2, _2#3]
```

compared with **Analysis** phase, reduced a SubqueryAlias



**RuleExecutor** is an important class.