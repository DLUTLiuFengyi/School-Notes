### Spring

#### Spring IoC

控制反转：（对象的控制权交由程序管理而不是程序员）由上层控制底层，而不是底层控制上层。这样底层对象的类代码发生改变时，上层对象代码不需要都进行改变。把对象创建和对象间的调用过程交给Spring进行管理，通过**反射**实现。

**当我们需要创建一个对象的时候，只需要配置好配置文件/注解即可，完全不用考虑对象是如何被创建出来的。** IOC 容器负责创建对象，将对象连接在一起，配置这些对象，并从创建中处理这些对象的整个生命周期，直到它们被完全销毁。

##### 目的

降低耦合性

##### 实现——通过依赖注入

依赖注入：依赖关系由spring来解决。spring通过xml配置读取要创建的对象的类名等属性信息，然后通过反射创建对象，放入bean容器中

本来我接受各种参数来构造一个对象，现在只接受一个参数——已经实例化的对象

##### 注入方式

* 接口注入（常用）传给上层对象构造函数的参数类型是一个接口，实际参数是一个接口的实现类
* getter，setter注入
* 构造器注入

而采用了依赖注入，在初始化的

#### IoC 容器

对对象（从下往上）进行初始化的代码发生的地方就是ioc容器

好处：

1. 这个容器可以自动对你的代码进行初始化，你只需要维护一个Configuration（可以是xml可以是一段代码），而不用每次初始化一辆车都要亲手去写那一大段初始化的new代码。

2. 用户在创建实例时不需要了解其中的细节

   ioc容器在进行new对象创建时，顺序是相反的（不是先new轮子再new车）它先从最上层往下找依赖关系，到达最底层后再往上一步步new，这里ioc容器对用户来说就像是一个工厂。用户给工厂config，工厂就自己创建出类。

#### Bean

Bean包括几个概念。

- 概念1：**Bean容器**，或称spring ioc容器，主要用来管理对象和依赖，以及依赖的注入。
- 概念2：bean是一个**Java对象**，根据bean规范编写出来的类，并由bean容器生成的对象就是一个bean。
- 概念3：bean规范。

##### 生命周期

1. 实例化Bean对象，两种方式

   * BeanFactory 使用到的时候才实例化bean对象
   * ApplicationContext 刚开始时就把所有bean对象都实例化了

2. 设置对象的属性

3. 检测有没有实现Aware相关的接口，设置相关的依赖

   xml初始化bean时，可以设置bean的id，这种就是aware

   走完123步后，bean对象基本就正确地构建了

4. 检测有没有实现BeanPostProcessor接口，如果有实现，那么就要实现前置处理方法

   * 检测是否实现InitializingBean接口
   * 检测并执行自定义方法

   和后置处理方法

   1-4步属于创建bean对象，然后将其放入依赖注入的容器（**单例池**，本质是个map）中

5. 使用中（从单例池map中拿对象 `applicationContext.getBean()`）

6. 使用完了后，检测是否实现Disposable接口，有的话就执行用户自定义的destroy方法

#### 循环依赖（非常重要）

```java
// A依赖B
Class A {
    @Autowired
    public B b;
}
// B依赖A
Class B {
    @Autowired
    public A a;
}
```

创建A对象需要在单例池中找到B属性的对象，单例池中没有B，需要创建B对象，而B又需要A

##### 解决方案（二级缓存）

加一个gupaoMap，gupaoMap<a, 原始对象>，先用一个不含B的原始对象A放进单例池中，这样在创建B时能直接使用单例池中的原始对象A，然后B对象创建成功，将B放入单例池，然后A就能成功设置B属性

**缺点** “设置其他属性”步骤中会遇到AOP问题

<img src="D:\ideaprojects\School-Notes\面试\pic\dit1.png" style="zoom:100%;" />

放入单例池中的应该是代理对象而不是原始对象，因此该方法在spring中不行

##### 解决方案（三级缓存）

把AOP操作（生成代理对象）那步放到put a 进单例池之前

**新问题** 并不是所有对象都需要提前AOP操作，只有产生循环依赖时才需要提前进行AOP操作。

解决：把AOP放到B对象创建流程中的在单例池中查找A对象是否存在的步骤之前

![](D:\ideaprojects\School-Notes\面试\pic\dit2.png)

**新问题** 如何知道A正在创建

解决：另外用一个CreateSet.add(A)，代表A正在创建，后面到B流程中判断有没有A对象时，先看CreateSet中有没有A，有的话就代表A正在创建。最后A流程完成后需要CreateSet.remove(A)

**新问题** 进行AOP的时候需要的是原始对象

解决：把gupaoMap<a, 对象>那步放回A流程，变回“原始对象”

![](D:\ideaprojects\School-Notes\面试\pic\dit3.png)

**新问题** A的代理对象是需要提前放入单例池中的

**新问题** 假如又有个C属性需要A

解决：新建一个SecondMap，用来加锁同步C属性从单例池中取出A

**总结**

一级缓存：单例池，二级缓存：SecondMap，三级缓存：gupaoMap

![](D:\ideaprojects\School-Notes\面试\pic\dit5.png)

**流程**

需要对象时，先去单例池找，单例池没有就去二级缓存找，secondmap中没有就判断是不是正在创建，正在创建的话就生成AOP代理对象，放到二级缓存中，然后从二级缓存中拿，二级缓存没有，就会从三级缓存中拿。从三级缓存拿到对象，就会把它放到二级缓存中，然后从三级缓存中将其删掉。（二级的put和三级的remove是成对出现的，使用前会synchronized上锁，因此这两个HashMap不需要设成ConcurrentHashMap）

#### 常见注解

@Autowired 自动导入对象到类中， Spring 容器帮我们自动装配 bean

@GetMapping("users")` 等价于`@RequestMapping(value="/users",method=RequestMethod.GET)

@PostMapping("users")` 等价于`@RequestMapping(value="/users",method=RequestMethod.POST)

`@SpringBootApplication`就是几个重要的注解的组合，为什么要有它？当然是为了省事，避免了我们每次开发 Spring Boot 项目都要写一些必备的注解。

```java
@RestController
@RequestMapping("test")
public class HelloWorldController {
    @GetMapping("hello")
    public String sayHello() {
        return "Hello World";
    }
}

//浏览器 http://localhost:8333/test/hello 可以在页面正确得到 "Hello World" 
```

#### 单例模式

spring实现单例的方式：

* 在xml的bean配置中添加参数
* 使用注解@Scope(value = "singleton")

**Spring 通过 `ConcurrentHashMap` 实现单例注册表的特殊方式实现单例模式。**

// 通过 ConcurrentHashMap（线程安全） 实现单例注册表

先检查缓存中是否存在实例，如果实例对象不存在，就将对象注册到单例注册表中

#### Spring AOP

AOP：面向切面编程

切面：横切面，与纵切面（面向对象中如何更详细地描述一个对象）相对，是众多类都会使用到的与业务无关的常规操作（日志、安全认证、事务等）

#### AOP增强

1. 前置增强 业务代码前面

2. 后置增强 业务代码后面

3. 环绕增强 1+2

4. 最终增强（返回增强）

   执行SQL流程最后提交事务时使用

5. 异常增强

执行SQL的例子同时体现出**代理模式**，执行sql前帮助执行一些操作（前置增强），然后返回的是一个代理对象

这个属于是动态代理

Spring中实现动态代理模式有2种：

* jdk 要实现一个接口
* cglib 默认使用

代理模式实现AOP的方法：工厂创建代理对象，代理对象里有一个成员属性，这个成员属性是被代理的原始对象的地址。代理对象包括：

* target属性（target = 循环依赖的例子中的a的原始对象）
* 代理逻辑

放入单例池中的不是原始对象而是代理对象

#### 代理模式

在不修改被代理对象的基础上，通过对代理类进行扩展，进行一些功能上的附加与增强。

静态代理每次都要重写接口方法，动态代理免去重写接口中的方法，着重于扩展相应的功能或是方法的增强，因此动态代理在实际开发中能大大减少项目的业务量。

**Spring AOP 就是基于动态代理的**，如果要代理的对象，实现了某个接口，那么Spring AOP会使用**JDK Proxy**，去创建代理对象，而对于没有实现接口的对象，就无法使用 JDK Proxy 去进行代理了，这时候Spring AOP会使用**Cglib** ，这时候Spring AOP会使用 **Cglib** 生成一个被代理对象的子类来作为代理

##### 静态代理

简单的java功能扩展，在编写代码时就已指定好，在runtime前就直到自己代理的是哪个类。

##### 动态代理

使用反射机制，在runtime的时候才知道自己代理的是哪个类。

jdk和cglib动态代理，都是通过 **运行时动态生成字节码** 的方式来实现代理的。

**jdk动态代理**

通过java反射机制，获取某个被代理类的所有接口，并创建代理类。

（代理类实现`InvocationHandler`接口）

通过`Proxy`类的静态方法`newProxyInstance`动态创建代理对象，传入参数是被代理类的类加载器、被代理类实现的所有接口、代理类的对象，然后调用代理对象的相关方法（被代理对象要使用的方法）即可。

**cglib动态代理**

使用cglib就无需声明接口了。

（代理类实现`MethodInterceptor`接口）

cglib生成的方法会继承被代理类（jdk动态代理是实现同一个接口），然后生成的方法也和jdk一样，会调用MethodInterceptor的intercept方法。

#### Restful风格

#### Spring中的设计模式

- **工厂设计模式** : Spring使用工厂模式通过 `BeanFactory`、`ApplicationContext` 创建 bean 对象。

- **代理设计模式** : Spring AOP 功能的实现。

- **单例设计模式** : Spring 中的 Bean 默认都是单例的。

  保证一个类只有一个实例，并提供一个访问它的全局访问点（构造方法是private的，外部不能调用）

- **模板方法模式** : Spring 中 `jdbcTemplate`、`hibernateTemplate` 等以 Template 结尾的对数据库操作的类，它们就使用到了模板模式。

- **包装器设计模式** : 我们的项目需要连接多个数据库，而且不同的客户在每次访问中根据需要会去访问不同的数据库。这种模式让我们可以根据客户的需求能够动态切换不同的数据源。

- **观察者模式:** Spring 事件驱动模型就是观察者模式很经典的一个应用。

- **适配器模式** :Spring AOP 的增强或通知(Advice)使用到了适配器模式、spring MVC 中也是用到了适配器模式适配`Controller`。

单例模式补充：getInstance() 方法中需要使用同步锁 synchronized (Singleton.class) 防止多线程同时进入造成 instance 被多次实例化。

### Spring Boot

自动装配

### Spring MVC

#### 结构

model处理数据逻辑的部分，通常负责在数据库中存取数据。

view处理数据显示的部分。通常是依据数据模型创建的。

controller处理数据交互的部分。通常负责从视图读取数据，控制用户输入，并向模型发送。

* 用户发请求
* 控制器接收请求，调用业务类，派发页面
* 交给模型层处理：model service dao entity
* 模型层返回一个结果给控制器
* 控制器视图渲染 view
* 控制器响应给用户

#### 流程说明（重要）

1. 客户端（浏览器）发送请求，直接请求到 `DispatcherServlet`。
2. `DispatcherServlet` 根据请求信息调用 `HandlerMapping`，解析请求对应的 `Handler`。
3. 解析到对应的 `Handler`（也就是我们平常说的 `Controller` 控制器）后，开始由 `HandlerAdapter` 适配器处理。
4. `HandlerAdapter` 会根据 `Handler `来调用真正的处理器来处理请求，并处理相应的业务逻辑。
5. 处理器处理完业务后，会返回一个 `ModelAndView` 对象，`Model` 是返回的数据对象，`View` 是个逻辑上的 `View`。
6. `ViewResolver` 会根据逻辑 `View` 查找实际的 `View`。
7. `DispaterServlet` 把返回的 `Model` 传给 `View`（视图渲染）。
8. 把 `View` 返回给请求者（浏览器）

![](D:\ideaprojects\School-Notes\面试\pic\mvc1.png)

#### 优缺点

封装（分层）的思想，来降低耦合度，从而使我们的系统更灵活，扩展性更好。

优点

* 多个视图共享一个模型，大大提高代码的可重用性。
* 三个模块相互独立，改变其中一个不会影响其他两，所以具有良好的松耦合性。
* 控制器可以用来连接不同的模型和视图去完成用户的需求，灵活。

缺点

* 增加结构复杂度

* 视图其实与控制器会过于紧密

  视图没有控制器的存在，其应用是很有限的

* 视图对模型数据的访问低效

  依据模型操作接口的不同，视图可能需要多次调用才能获得足够的显示数据。对未变化数据的不必要的频繁访问，也将损害操作性能。

#### Spring MVC的适配器模式

适配器模式是将一个接口转换成客户希望的另一个接口，使接口不兼容的类可以一起工作

DispatcherServlet根据请求信息调用HandlerMapping，解析请求对应的Handler，解析到对应的Handler（也就是Controller）后，开始由HandlerAdpter适配器处理。HandlerAdapter作为期望接口，具体的适配器实现类用于对目标类进行适配，Controller作为需要适配的类。

为什么用适配器模式？ Spring MVC中的Controller种类众多，不同的Controller通过不同的方法对请求进行处理，如果不利用适配器模式的话，DipatcherServlet直接获取对应类型的Controller，需要自行来判断：

如果获取到的handler是xxx类型Controller的实例，就调用xxx类型的handler。在这种场景下，添加一个Controller类型，就要加一行判断语句，使程序难以维护。

#### SpringBoot自动装配原理

三个角度：什么是自动装配；如何实现自动装配，如何实现按需加载；如何实现一个starter

spring xml配置复杂，对spring boot项目，只需添加相关依赖，无需配置，通过启动main方法即可

且通过其全局配置文件`application.properties`即可对项目进行相关设置

```txt
spring boot定义了一套接口规范，规定spb在启动时会扫描外部引用jar包中的META-INF/spring.factories文件，将文件中配置的类型信息加载到spring容器（此处涉及jvm类加载机制与spring容器），并执行类中定义的各种操作。对外部jar来说，只需按照spb定义的标准，就能将自己的功能装置进springboot
```

没有 Spring Boot 的情况下，如果我们需要引入第三方依赖，需要手动配置，非常麻烦。但是，Spring Boot 中，我们直接引入一个 **starter** 即可。比如你想要在项目中使用 redis 的话，直接在项目中引入对应的 starter 即可。

自动装配简单概括位：**通过注解或者一些简单的配置就能在 Spring Boot 的帮助下实现某块功能。**

##### 如何实现

核心注解`SpringBootApplication`，是 `@Configuration`、`@EnableAutoConfiguration`、`@ComponentScan` 注解的集合

- `@EnableAutoConfiguration`：启用 SpringBoot 的自动配置机制

  核心功能通过AutoConfigurationImportSelector实现，其中的getAutoConfigurationEntry()负责加载自动装配类。后者调用相关方法通过从META-INF/spring.factories加载自动装配类来获取所有自动配置类名

- `@Configuration`：允许在上下文中注册额外的 bean 或导入其他配置类

- `@ComponentScan`： 扫描被`@Component` (`@Service`,`@Controller`)注解的 bean，注解默认会扫描启动类所在的包下所有的类 ，可以自定义不扫描某些 bean。

**总结**： Spring Boot 通过`@EnableAutoConfiguration`开启自动装配，通过 SpringFactoriesLoader 最终加载外部jar包中的`META-INF/spring.factories`中的自动配置类实现自动装配。自动配置类其实就是通过`@Conditional`按需加载的配置类，想要其生效必须引入`spring-boot-starter-xxx`包实现起步依赖

**自己写一个star**

1. 自己项目导入star依赖
2. 写Configuration类
3. 在resources包下创建META-INF/spring.factories文件，里指明EnableAutoConfiguration为自己的Configuration类
4. 然后新建springboot工程引入自己的star项目

#### SpringBoot启动流程

1. main方法，SpringApplication.run

   所在类需要@SpringBootApplication注解，其表示开启Spring的组件扫描和Spring Boot的自动装配，分成

   * @EnableAutoConfiguration：开启自动装配
   * @Configuration：标明该类使用Spring基于Java的配置，提供上下文环境
   * @ComponentScan：启用组件扫描，扫描被@Component注解的bean

### 设计模式

#### 代理模式

在直接访问对象时带来的问题，比如说：要访问的对象在远程的机器上。在面向对象系统中，有些对象由于某些原因（比如对象创建开销很大，或者某些操作需要安全控制，或者需要进程外的访问），直接访问会给使用者或者系统结构带来很多麻烦，我们可以在访问此对象时加上一个对此对象的访问层。