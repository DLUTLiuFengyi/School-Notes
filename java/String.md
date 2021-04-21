### Definition

* String

  immutable(that char[] values array is final)

* StringBuffer

  mutable

  thread-safe(synchronous)

  little slower than StringBuilder

* StringBuilder

  mutable

  not thread-safe



### Comparable cases

```java
//测试代码  
public class RunTime{  
    public static void main(String[] args){  
           ● 测试代码位置1  
          long beginTime=System.currentTimeMillis();  
          for(int i=0;i<10000;i++){  
                 ● 测试代码位置2  
          }  
          long endTime=System.currentTimeMillis();  
          System.out.println(endTime-beginTime);     
    }  
} 
```

```java
ONE
位置1 String str="";
位置2 str="Heart"+"Raid";
0ms

TWO
位置1 String s1="Heart";
     String s2="Raid";
     String str="";
位置2 str=s1+s2;
15-16ms
    
THREE
位置1 String s1="Heart";
     StringBuffer sb=new StringBuffer();
位置2 sb.append(s1)
```

ONE: 

"Heart"+"Raid" connect during compile stage and form a String constant, pointing to the **detention String object** in the heap. When exe-ing, just need to extract the address of the detention String object "HeartRaid" for 1w times and store it in the local variable str.

TWO: 

```java
StringBuilder temp = new StringBuilder(s1)
temp.append(s2)
str=temp.toString()
```

s1 and s2 stores two diff addresses of detention String objects. In the beginning and end, creates StringBuilder and String. Value[] array in String is immutable, so has to create a new String object to store the result after connection, so creates 1w times String object and 1w times StringBuilder object.

THREE:

Just need to continue expanding the value[] array to store s1, no need to create any new object in the heap during the loop. 