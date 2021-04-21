## Channel  通信

参考博客

[异构模块之间如何数据传输？举例java和python两种不同语言编写的模块之间数据交互的几种方式（入门消息队列RabbitMQ）](https://blog.csdn.net/pig2guang/article/details/84382375?utm_medium=distribute.pc_aggpage_search_result.none-task-blog-2~all~first_rank_v2~rank_v25-1-84382375.nonecase&utm_term=java%E4%B8%8Epython%E5%A6%82%E4%BD%95%E6%95%B0%E6%8D%AE%E4%BA%A4%E4%BA%92)



### 方案选择

* RDMA

  老师在长远方向上的选择，我觉得现在阶段用消息队列或许就可以

* 消息队列

  RabbitMQ

* java调用python脚本

* Jython  

  用纯Java实现Pyhton语言，用户可以以pyhon语言编写在jvm上运行的程序

* 网络通讯 

  socket tcp/ip

* rpc

* 文件作为中间站



### RabbitMQ



