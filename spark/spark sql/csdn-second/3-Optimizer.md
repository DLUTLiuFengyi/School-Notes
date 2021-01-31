---
typora-root-url: pic
---

## Optimizer

![](/optimizer1.png)

![](/optimizer2.png)

Optimizer and Analyzer all extend RuleExecutor[LogicalPlan], all do a series of Batch operation

three kinds of optimization

* Combine Limits
* Constant Folding
* Filter Pushdown

```scala
object Optimizer extends RuleExecutor[LogicalPlan] {
  val batches =
    Batch("Combine Limits", FixedPoint(100),
      CombineLimits) ::
    Batch("ConstantFolding", FixedPoint(100),
      NullPropagation,
      ConstantFolding,
      BooleanSimplification,
      SimplifyFilters,
      SimplifyCasts,
      SimplifyCaseConversionExpressions) ::
    Batch("Filter Pushdown", FixedPoint(100),
      CombineFilters,
      PushPredicateThroughProject,
      PushPredicateThroughJoin,
      ColumnPruning) :: Nil
}
```

