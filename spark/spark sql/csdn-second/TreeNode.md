---
typora-root-url: pic
---

## TreeNode

TreeNode Library is the **core** lib of **Catalyst**. one by one TreeNode constructing AST.

TreeNode is `BaseType <: TreeNode[BaseType]`, and implements the trait `Product` , so that can store Heterogeneous elems.

three kinds of TN:

* BinaryNode
* UnaryNode
* Leaf Node

those Nodes are all extend **Logical Plan** in catalyst, you can say **each TN is a Logical Plan(include Expression) (directly extends TN)**

![](/treenode1.png)

### BinaryNode

```scala
trait BinaryNode[BaseType <: TreeNode[BaseType]] {
  def left: BaseType
  def right: BaseType
  def children = Seq(left, right)
}
abstract class BinaryNode extends LogicalPlan with trees.BinaryNode[LogicalPlan] {
  self: Product =>       // now can use `self` as same as `this`
 }
```

Common BN

* Join
* Union



### UnaryNode

```scala
trait UnaryNode[BaseType <: TreeNode[BaseType]] {
  def child: BaseType
  def children = child :: Nil
}
abstract class UnaryNode extends LogicalPlan with trees.UnaryNode[LogicalPlan] {
  self: Product =>
}
```

Common UN

* Project
* Subquery
* Filter
* Limit



### LeafNode

```scala
trait LeafNode[BaseType <: TreeNode[BaseType]] {
  def children = Nil
}
abstract class LeafNode extends LogicalPlan with trees.LeafNode[LogicalPlan] {
  self: Product =>
  // Leaf nodes by definition cannot reference any input attributes.
  override def references = Set.empty
}
```

Common LN

* Common
* some Function
* Unresolved Relation



### transform

```scala
object GlobalAggregates extends Rule[LogicalPlan] {
    def apply(plan: LogicalPlan): LogicalPlan = plan transform {   //apply方法这里调用了logical plan（TreeNode） 的transform方法来应用一个PartialFunction
      case Project(projectList, child) if containsAggregates(projectList) =>
        Aggregate(Nil, projectList, child)
    }
    def containsAggregates(exprs: Seq[Expression]): Boolean = {
      exprs.foreach(_.foreach {
        case agg: AggregateExpression => return true
        case _ =>
      })
      false
    }
  }
```

this method calls **transformChildrenDown**, first **preorder traversal** the child recursively to applicate Rule. if rules current node successfully, applicates rule in children nodes 

```scala
   /**
   * Returns a copy of this node where `rule` has been recursively applied to it and all of its
   * children (pre-order). When `rule` does not apply to a given node it is left unchanged.
   * @param rule the function used to transform this nodes children
   */
  def transformDown(rule: PartialFunction[BaseType, BaseType]): BaseType = {
    val afterRule = rule.applyOrElse(this, identity[BaseType])
    // Check if unchanged and then possibly return old copy to avoid gc churn.
    if (this fastEquals afterRule) {
      transformChildrenDown(rule)  //修改前节点this.transformChildrenDown(rule)
    } else {
      afterRule.transformChildrenDown(rule) //修改后节点进行transformChildrenDown
    }
  }
```

the most important method **transformChildrenDown**. recursively applicates **PartialFunction** to children nodes, uses the **newArgs** that returned at last to generate a new node(here uses `makeCopy()`)

```scala
  /**
   * Returns a copy of this node where `rule` has been recursively applied to all the children of
   * this node.  When `rule` does not apply to a given node it is left unchanged.
   * @param rule the function used to transform this nodes children
   */
  def transformChildrenDown(rule: PartialFunction[BaseType, BaseType]): this.type = {
    var changed = false
    val newArgs = productIterator.map {
      case arg: TreeNode[_] if children contains arg =>
        val newChild = arg.asInstanceOf[BaseType].transformDown(rule) //递归子节点应用rule
        if (!(newChild fastEquals arg)) {
          changed = true
          newChild
        } else {
          arg
        }
      case Some(arg: TreeNode[_]) if children contains arg =>
        val newChild = arg.asInstanceOf[BaseType].transformDown(rule)
        if (!(newChild fastEquals arg)) {
          changed = true
          Some(newChild)
        } else {
          Some(arg)
        }
      case m: Map[_,_] => m
      case args: Traversable[_] => args.map {
        case arg: TreeNode[_] if children contains arg =>
          val newChild = arg.asInstanceOf[BaseType].transformDown(rule)
          if (!(newChild fastEquals arg)) {
            changed = true
            newChild
          } else {
            arg
          }
        case other => other
      }
      case nonChild: AnyRef => nonChild
      case null => null
    }.toArray
    if (changed) makeCopy(newArgs) else this //根据作用结果返回的newArgs数组，反射生成新的节点副本。
  }
```

makeCopy method, reflect to generate node copy

```scala
 /**
   * Creates a copy of this type of tree node after a transformation.
   * Must be overridden by child classes that have constructor arguments
   * that are not present in the productIterator.
   * @param newArgs the new product arguments.
   */
  def makeCopy(newArgs: Array[AnyRef]): this.type = attachTree(this, "makeCopy") {
    try {
      val defaultCtor = getClass.getConstructors.head  //反射获取默认构造函数的第一个
      if (otherCopyArgs.isEmpty) {
        defaultCtor.newInstance(newArgs: _*).asInstanceOf[this.type] //反射生成当前节点类型的节点
      } else {
        defaultCtor.newInstance((newArgs ++ otherCopyArgs).toArray: _*).asInstanceOf[this.type] //如果还有其它参数，++
      }
    } catch {
      case e: java.lang.IllegalArgumentException =>
        throw new TreeNodeException(
          this, s"Failed to copy node.  Is otherCopyArgs specified correctly for $nodeName? "
            + s"Exception message: ${e.getMessage}.")
    }
  }
```



### TreeNode example

```sql
select * from (select * from src) a join (select * from src) b on a.key = b.key
```

#### UnResolved Logical Plan

```scala
scala> query.queryExecution.logical
res0: org.apache.spark.sql.catalyst.plans.logical.LogicalPlan = 
Project [*]
 Join Inner, Some(('a.key = 'b.key))
  Subquery a
   Project [*]
    UnresolvedRelation None, src, None
  Subquery b
   Project [*]
    UnresolvedRelation None, src, None
```

![](/treenode2.png)

#### Analyzed Logical Plan

**Analyzer** allows **Rules** in Batch to applicate rule on **unresolved Logical Plan**

here use `EliminateAnalysisOperator` to eliminate **Subquery**

![](/treenode3.png)

#### Optimized Plan

```scala
scala> query.queryExecution.optimizedPlan
res3: org.apache.spark.sql.catalyst.plans.logical.LogicalPlan = 
Project [key#0,value#1,key#2,value#3]
 Join Inner, Some((key#0 = key#2))
  MetastoreRelation default, src, None
  MetastoreRelation default, src, None
```

![](/treenode4.png)

#### executedPlan

Hive's `TableScan` `TableJoin` `Exchange`(`Shuffle``Partition`)

```scala
scala> query.queryExecution.executedPlan
res4: org.apache.spark.sql.execution.SparkPlan = 
Project [key#0:0,value#1:1,key#2:2,value#3:3]
 HashJoin [key#0], [key#2], BuildRight
  Exchange (HashPartitioning [key#0:0], 150)
   HiveTableScan [key#0,value#1], (MetastoreRelation default, src, None), None
  Exchange (HashPartitioning [key#2:0], 150)
   HiveTableScan [key#2,value#3], (MetastoreRelation default, src, None), None
```

![](/treenode5.png)



### Conclution

 TreeNode的transform方法是核心的方法，它接受一个rule，会对当前节点的孩子节点进行递归的调用rule，最后会返回一个TreeNode的copy，这种操作就是transformation，贯穿了Spark SQL执行的几个核心阶段，如Analyze，Optimize阶段。