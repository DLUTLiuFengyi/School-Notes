java命令运行.class文件

```shell
# 通常情况
javac xxx.java
java xxx
# 类含有包名
# 则在第一层包目录的上一级目录运行
# 例如在\src\main\java目录里运行
java com.....xxx
```



**注意**

“找不到或无法加载主类”

* META-INF文件里的MANIFEST.MF文件里是否写明Main-Class属性

* pom里的依赖是否有版本冲突

  例如spark.version用2.4.5，jar包可执行；用1.6.1，jar包不可执行

  

### URI

https://blog.csdn.net/qbw2010/article/details/72868802

http://www.voidcn.com/article/p-tdqrttii-k.html

https://www.cnblogs.com/macwhirr/p/8116583.html