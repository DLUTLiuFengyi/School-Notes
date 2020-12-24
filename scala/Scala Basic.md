### Companion Object

Has the same name as class(class Json, object Json)

Methods in companion object can be used as static method in java

#### Apply - Factory Model

Used in the object has only one method(apply)

```scala
class Foo{}

object FooMaker {
    def apply() = new Foo
}

val newFoo = FooMaker() 
//newFoo: Foo = Foo@xxxxx
```

 

### PartialFunction

**PartialFunction[A, B]** receive A type argu and return B type argu

**case** a keyword in pf

```scala
val one: PartialFunction[Int, String] = {case 1 => "one"}

one(1)
```

```scala
val list:List[Any] = List(1, 3, 5, "seven")
list.map {case i: Int => i+1} // Error
list.collect {case i: Int => i+1}
// Correct, because collect receives pf as argu and use pf characteristic automatically, so filters types not matching automatically.
// List[Int] = List(2, 4, 6)
```



### PartialApplyFunction

Can only transfer partial argus when call a fun.

```scala
def partial(i:Int, j:Int) : Unit = {
    | println(i)
    | println(j)
    |
}
val partialFun = partial(5, _: Int)
partialFun(10)
// 5
// 10
```



### Curry Function

Transfer a func to a call chain of several funcs. Used for functional dependency injection.

```scala
def curring(i:Int)(j:Int): Boolean = {false}

// Assign the func to a variable
val curringVal: (Int => (Int => Boolean)) = curring _
// curringVal: Int => (Int => Boolean) = <function1>

// Make the variable receive an argu to become another func
val curringVal_1 = curringVal(5)
// curringVal_1: Int => Boolean = <function1>

// Let the variable recieve an argu
curringVal_1(10)
// Boolean = false
```



### Generic paradigm

Gp in scala calls variance. Dog is subclass of Animal, then:

* covariant

  List[Dog] is subclass of List[Animal] -> List[+A]

* contravariant

  contrary of covariant. List[Animal] is subclass of List[Dog] -> List[-A]

* invariant

  List[Dog] is irrelevant of List[Animal] -> List[A]



### Syntactic sugar

#### _*

Parameters other than the first parameters

#### case class

java bean

#### [A]

[A] in apply [A] (as: A*) means multi argus 

#### implicit

Implicit transformation

```scala
val numList = SList(1,2,3,4,5)
// before
SList.sum(numList)
// after
numList.sum()
```



### Implicit

A repair mechanism handling compile type error, can help to code any types of argument and return items. 

This polymorphism also be called Ad-hoc polymorphism. Use Magnet Pattern to achieve.

**Implicit Convert Method** effects in the same scope of original methods. It automatically convert the input type to the defined type. This implicit method is irrelevant to the original method.