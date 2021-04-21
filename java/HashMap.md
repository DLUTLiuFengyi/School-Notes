## HashMap

#### 内存占用

```java
Integer a = 1;
long start = 0;
long end = 0;
// 先垃圾回收
System.gc();
start = Runtime.getRuntime().freeMemory();
HashMap map = new HashMap();
for (int i = 0; i < 1000000; i++) {
    map.put(i, a);
}
// 快要计算的时,再清理一次
System.gc();
end = Runtime.getRuntime().freeMemory();
System.out.println("一个HashMap对象占内存:" + (end - start));
```

默认最大容量是2的30次方（1 073 741 824）

#### 扩容

rehash、复制数据，非常消耗性能

#### 拉链法

数组 + 链表（桶）

#### 插入

hash值为 hash(key) ，因此key相等也代表hash相等

* 如果定位到的数组位置没有元素，就直接插入
* 如果定位到的数组位置有元素，就和要插入的key比较：
  * 如果key相同，就直接覆盖
  * 如果key不相同，就判断p是否是一个树节点
    * 如果是，就调用`e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value)`将元素添加进入
    * 如果不是就遍历链表插入。