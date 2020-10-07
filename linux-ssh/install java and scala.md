### Install Java

Download jdk from oracle web (jdk-8u261-linux-x64.gz)

http://www.oracle.com/technetwork/articles/javase/index-jsp-138363.html

cd ~

Transfer to linux use rz (by xshell)

sudo mkdir /usr/lib/jvm

sudo tar -zxvf jdk-8u261-linux-x64.gz -C /usr/lib/jvm

sudo vim ~/.bashrc

Add in the end of file

```shell
#set oracle jdk environment
export JAVA_HOME=/usr/lib/jvm/jdk1.8.0_261  
export JRE_HOME=${JAVA_HOME}/jre  
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib  
export PATH=${JAVA_HOME}/bin:$PATH  
```

source ~/.bashrc

java -version



### Install Scala

We should have java installed first.

https://www.scala-lang.org/download/2.11.8.html

Download scala-2.11.8.tgz

cd ~

Transfer to linux use rz (by xshell)

tar -zxvf scala-2.11.8.tgz

mv scala-2.11.8/ scala

sudo mv scala/ /usr/lib/

sudo vim ~/.bashrc

Add in the end of file

```shell
#set scala env
export SCALA_HOME=/usr/lib/scala
export PATH=${JAVA_HOME}/bin:${SCALA_HOME}/bin:$PATH
```

source ~/.bashrc

scala

:quit



### Exe scala

#### Direct

scala xxx.scala [args] [args]

#### Compile first

scalac xxx.scala

scala xxx