### ForkJoinPool

**Java8的parallel基于ForkJoinPool**

jdk7

它同ThreadPoolExecutor一样，也实现了Executor和ExecutorService接口

* 使用一个**无限队列**来保存需要执行的任务
* 线程的数量通过构造函数传入，若没有指定则默认值为当前计算机可用的CPU数量

ForkJoinPool主要用来使用**分治法(Divide-and-Conquer Algorithm)**来解决问题，典型的应用比如快速排序算法。

这里的要点在于，ForkJoinPool需要**使用相对少的线程来处理大量的任务**。

比如要对1000万个数据进行排序，那么会将这个任务分割成两个500万的排序任务和一个针对这两组500万数据的合并任务。以此类推，对于500万的数据也会做出同样的分割处理，到最后会设置一个阈值来规定当数据规模到多少时，停止这样的分割处理。比如，当元素的数量小于10时，会停止分割，转而使用插入排序对它们进行排序。那么到最后，所有的任务加起来会有大概2000000+个。

问题的关键在于，对于一个任务而言，只有当它所有的子任务完成之后，它才能够被执行。

所以当使用ThreadPoolExecutor时，使用分治法会存在问题，因为ThreadPoolExecutor中的线程无法像任务队列中再添加一个任务并且在等待该任务完成之后再继续执行。而使用ForkJoinPool时，就能够让其中的线程创建新的任务，并挂起当前的任务，此时线程就能够从队列中选择子任务执行。

#### 性能的差异
使用ForkJoinPool能够使用数量有限的线程来完成非常多的具有父子关系的任务

* 比如使用4个线程来完成超过200万个任务

使用ThreadPoolExecutor时，是不可能完成的，因为ThreadPoolExecutor中的Thread无法选择优先执行子任务

* 需要完成200万个具有父子关系的任务时，也需要200万个线程

#### 工作窃取算法

working-stealing is the core of forkjoin

工作窃取算法指某个线程从其他队列里窃取任务来执行

假如需要做一个比较大的任务：

* 把这个任务分割为若干互不依赖的子任务。

* 为了减少线程间的竞争，把这些子任务分别放到不同的队列里，并为每个队列创建一个单独的线程来执行队列里的任务，**线程和队列一一对应**。
* 但是有的线程会先把自己队列里的任务干完，而其他线程对应的队列里还有任务等待处理。干完活的线程与其等着，不如去帮其他线程干活，于是它就去其他线程的队列里**窃取一个任务**来执行。
* 而在这时它们会访问同一个队列，所以为了减少窃取任务线程和被窃取任务线程之间的竞争，通常会使用**双端队列**，被窃取任务线程永远从双端队列的头部拿任务执行，而窃取任务的线程永远从双端队列的尾部拿任务执行。

优点：

利用线程进行并行计算，并减少了线程间的竞争

缺点：

某些情况下还是存在竞争，比如双端队列里只有一个任务时。

并且消耗了更多的系统资源，比如创建多个线程和多个双端队列。

#### Java8

在Java 8引入了自动并行化的概念。它能够让一部分Java代码自动地以并行的方式执行，也就是使用了ForkJoinPool的ParallelStream。

Java 8为ForkJoinPool添加了一个通用线程池，这个线程池用来处理那些没有被显式提交到任何线程池的任务。它是ForkJoinPool类型上的一个静态元素，它拥有的默认线程数量等于运行计算机上的处理器数量。

当调用Arrays类上添加的新方法时，自动并行化就会发生。比如用来排序一个数组的并行快速排序，用来对一个数组中的元素进行并行遍历。

下面的代码用来遍历列表中的元素并执行需要的操作

```java
List<UserInfo> userInfoList =
        DaoContainers.getUserInfoDAO().queryAllByList(new UserInfoModel());
    userInfoList.parallelStream().forEach(RedisUserApi::setUserIdUserInfo);
```

对于列表中的元素的操作都会以并行的方式执行。forEach方法会为每个元素的计算操作创建一个任务，该任务会被前文中提到的ForkJoinPool中的通用线程池处理。

以上的并行计算逻辑当然也可以使用ThreadPoolExecutor完成，但是ForkJoinPool的代码可读性和代码量明显更胜一筹。

对于ForkJoinPool通用线程池的线程数量，默认值是运行时计算机的处理器数量。

jvm所使用的ForkJoinPool的线程数量可以通过设置系统属性

`-Djava.util.concurrent.ForkJoinPool.common.parallelism=N （N为线程数量）`

来调整ForkJoinPool的线程数量:

```java
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.concurrent.CountDownLatch;
 
/**
 * @description parallelStream原理实例
 * @author from csdn wangguangdong 
 */
public class App {
    public static void main(String[] args) throws Exception {
        System.out.println("Hello World!");
        // 构造一个10000个元素的集合
        List<Integer> list = new ArrayList<>();
        for (int i = 0; i < 10000; i++) {
            list.add(i);
        }
        // 统计并行执行list的线程
        Set<Thread> threadSet = new CopyOnWriteArraySet<>();
        // 并行执行
        list.parallelStream().forEach(integer -> {
            Thread thread = Thread.currentThread();
            // System.out.println(thread);
            // 统计并行执行list的线程
            threadSet.add(thread);
        });
        System.out.println("threadSet一共有" + threadSet.size() + "个线程");
        System.out.println("系统一个有"+Runtime.getRuntime().availableProcessors()+"个cpu");
        List<Integer> list1 = new ArrayList<>();
        List<Integer> list2 = new ArrayList<>();
        for (int i = 0; i < 100000; i++) {
            list1.add(i);
            list2.add(i);
        }
        Set<Thread> threadSetTwo = new CopyOnWriteArraySet<>();
        CountDownLatch countDownLatch = new CountDownLatch(2);
        Thread threadA = new Thread(() -> {
            list1.parallelStream().forEach(integer -> {
                Thread thread = Thread.currentThread();
                // System.out.println("list1" + thread);
                threadSetTwo.add(thread);
            });
            countDownLatch.countDown();
        });
        Thread threadB = new Thread(() -> {
            list2.parallelStream().forEach(integer -> {
                Thread thread = Thread.currentThread();
                // System.out.println("list2" + thread);
                threadSetTwo.add(thread);
            });
            countDownLatch.countDown();
        });
 
        threadA.start();
        threadB.start();
        countDownLatch.await();
        System.out.print("threadSetTwo一共有" + threadSetTwo.size() + "个线程");
 
        System.out.println("---------------------------");
        System.out.println(threadSet);
        System.out.println(threadSetTwo);
        System.out.println("---------------------------");
        threadSetTwo.addAll(threadSet);
        System.out.println(threadSetTwo);
        System.out.println("threadSetTwo一共有" + threadSetTwo.size() + "个线程");
        System.out.println("系统一个有"+Runtime.getRuntime().availableProcessors()+"个cpu");
    }
}
```

出现这种现象的原因是，forEach方法用了一些小把戏。它会将执行forEach本身的线程也作为线程池中的一个工作线程。

因此，即使将ForkJoinPool的通用线程池的线程数量设置为1，实际上也会有2个工作线程。因此在使用forEach的时候，线程数为1的ForkJoinPool通用线程池和线程数为2的ThreadPoolExecutor是等价的。

所以当ForkJoinPool通用线程池实际需要4个工作线程时，可以将它设置成3，那么在运行时可用的工作线程就是4了。

#### 总结

1. 当需要处理递归分治算法时，考虑使用ForkJoinPool。
2. 仔细设置不再进行任务划分的阈值，这个阈值对性能有影响。
3. Java 8中的一些特性会使用到ForkJoinPool中的通用线程池。在某些场合下，需要调整该线程池的默认的线程数量。