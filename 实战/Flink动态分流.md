网址：https://mp.weixin.qq.com/s/Ljv0QARXDFmpnfFpAmqpjg

* flink原生side output分流

  需要预先定义分流标记，不支持连续分流，不能根据分流条件的增减来动态分流

* flink CEP

  繁琐，杀鸡用牛刀

* flink 双流方案

  一条读取配置信息流，一条数据处理流，通过广播变量更新节点信息，利用多线程和缓存，结合动态脚本来实现动态分流