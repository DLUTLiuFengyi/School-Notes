## A Blog

### Process

* SQL   ->   [Antlr4]   -> Unresolved Logical Plan

  1. antlr4: sql -> syntax tree
  2. visitor mode in antlr4: syntax tree -> logical plan

  class AstBuilder (in step 2)

  * from
  * withQuerySpecification [use scala pattern matching]: select, filter, group by, having

*   Unresolved Logical Plan   ->   [analyzer]   ->   (Resolved) Logical Plan

  Unresolved represents we don't know whether src, schema exist, don't know the type of one col or whether the col exists.





 ## Tencent cloud - the main progress of Spark SQL

### Tree and Rule

TreeNode

- Literal(value: Int): 一个常量
- Attribute(name: String): 变量name
- Add(left: TreeNode, right: TreeNode): 两个表达式的和

x+(1+2)   =>   Add(Attribute(x), Add(Literal(1), Literal(2)))

![](D:\ideaprojects\yanjiushengbiji\spark\spark sql\ast1.png)

Rule: the rules used on Tree. By pattern matching, matching success -> use the transfer of rule, matching fail -> continue to match child nodes

```scala
expression.transform {
    case Add(Literal(x, IntergeType), Literal(y, IntergeType)) => Literal(x+y)
}
```



### flow chart

![](D:\ideaprojects\yanjiushengbiji\spark\spark sql\ast2.png)

#### general process

- sqlText 经过 SqlParser 解析成 Unresolved LogicalPlan;

- analyzer 模块结合catalog进行绑定,生成 resolved LogicalPlan;

- optimizer 模块对 resolved LogicalPlan 进行优化,生成 optimized LogicalPlan;

- SparkPlan 将 LogicalPlan 转换成PhysicalPlan;

- prepareForExecution()将 PhysicalPlan 转换成可执行物理计划;

- 使用 execute()执行可执行物理计划;

  

#### Parser

* sqlText change to AST using SparkSqlParser
* AstBuilder cooperates visitor mode in antlr to traverse Tee, change the nodes in antlr to the type in  **catalyst **(optimizer system), all types inherit traits of **TreeNode**, the TreeNode has child node Children: Seq[BaseType], so that get the tree structure
* the AST got from this step is called unresolved Logical Plan

#### Analyzer

* in **Parse** phase, we just split the SQL using antlr4 and change into many kinds of  Logical Plan(the subclass of TreeNode) by **SparkSqlParser**. we don't know the meaning of each Logical Plan yet.
* Use Analyzer to identify the attributes and relationships that were not identified previously using **catalog** and some Adapter methods, such as parse out tablename 'user' from catalog, and schema ...whether is hive table or hive view ...
* the real executor of applicating each kind of Rule on the Tree is **RuleExecutor**, the Optimizer later also extends RuleExecutor. The parsing is traversing recursively, replacing old Logical Plan with new parsing Logical Plan.
* the AST got from this step is called resolved Logical Plan

#### Optimizer

* SQL optimization: predicate push down ...
* this Optimizer also extends RuleExecutor, and define some rules. the same as Analyzer, recursively processing the input plan
* the AST got from this step is called optimized Logical Plan

#### SparkPlanner

* applicating the optimized Logical Plan to some specified Strategies using SparkPlanner, that is to say, changing to operation and data that can be operated directly, and the binding of RDD
* the AST got from this step is called Physical Plan

#### prepareForExecution

* changing the Physical Plan to Executable Physical Plan: inserting shuffle, format transferring of internal row ...

#### execute

* call SparkPlan.execute(), each SparkPlan has the implement of `execute`, in general, calling children's `execute()` recursively, and triggers the computation of the whole Tree.



![](D:\ideaprojects\yanjiushengbiji\spark\spark sql\sparksqlcode3.png)



![](D:\ideaprojects\yanjiushengbiji\spark\spark sql\sparksqlcode1.png)

![](D:\ideaprojects\yanjiushengbiji\spark\spark sql\sparksqlcode2.png)