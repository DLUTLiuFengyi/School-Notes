---
typora-root-url: ..\pic
---

cache中存储cpu常用的热点数据，避免cpu总是需要直接从速度慢的内存中读取数据

cpu需要读数据时：
1. cpu从cache中查找是否有数据，若没有，cpu从内存中读数据到cache
2. cpu从cache中读数据

cpu需要写数据时：
1. cpu从cache中查找是否有请求的地址对应的数据
2. 若有，cpu将数据写入cache
3. 若没有，cpu将请求地址写进cache，将对应数据保存进cache

<img src="/cache1.png" style="zoom:70%;" />

287  1107  1913

