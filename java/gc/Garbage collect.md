### 垃圾回收

在Java程序中，我们通常使用new为对象分配内存，而这些内存空间都在堆（Heap）上。

```java
public class Test {
    public static void main(String args[]){
        Object object1 = new Object();//obj1
        Object object2 = new Object();//obj2
        object2 = object1;  
    }
}
```

上面代码创建了两个对象obj1和obj2，这两个对象各占用了一部分内存，然而，两个对象引用变量object1和object2同时指向obj1的那块内存，而obj2是不可达的.

由于java垃圾回收的目标，是清理那些不可达的对象所占内存，**释放对象的根本原则就是对象不会再被使用（也就是没有引用变量指向该对象所占内存空间），所以**obj2可以被清理。

#### 内存泄漏

当某些对象不再被应用程序所使用,但是由于仍然被引用而导致垃圾收集器不能释放(Remove,移除)他们

