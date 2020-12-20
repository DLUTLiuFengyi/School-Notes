**interface Operator**

#### 1

**interface ActualOperator extends Operator**

无歧义算子

accept方法

**interface ElementaryOperator extends ActualOperator**

不包含其他运算符的不可分割运算符

##### 1.1

**interface ExecutionOperator extends ElementaryOperator**

一个被确切平台使用的可执行算子

**interface JavaExecutionOperator extends ExecutionOperator**

Java平台的可执行算子

#### 2

**abstract class OperatorBase implements Operator**

实现Operator接口

#### 1+2

**abstract class UnaryToUnaryOperator<InputType, OutputType> extends OperatorBase implements ElementaryOperator**

一个输入类型和一个输出类型的算子

**SortOperator<Type, Key> extends UnaryToUnaryOperator<Type, Type>**

对dataset中的元素进行排序



#### 1+2+1.1

**JavaSortOperator<Type, Key> extends SortOperator<Type, Key> implements JavaExecutionOperator**

Java中的sort算子实例