## SqlParser

SqlParser is a SQL parser, Parser encapsulate parsed result into **Catalyst TreeNode**

![](D:\ideaprojects\yanjiushengbiji\spark\spark sql\csdn-second\sqlparser1.png)

Unresolved Logical Plan includes

* UnresolvedRelation
* UnresolvedFunction
* UnresolvedAttribute

### entrance of SQL Parser

```scala
def sql(sqlText: String): SchemaRDD = new SchemaRDD(this, parseSql(sqlText))//sql("select name,value from temp_shengli") 实例化一个SchemaRDD
 
protected[sql] def parseSql(sql: String): LogicalPlan = parser(sql) //实例化SqlParser
 
class SqlParser extends StandardTokenParsers with PackratParsers {
 
  def apply(input: String): LogicalPlan = {  //传入sql语句调用apply方法，input参数即sql语句
    // Special-case out set commands since the value fields can be
    // complex to handle without RegexParsers. Also this approach
    // is clearer for the several possible cases of set commands.
    if (input.trim.toLowerCase.startsWith("set")) {
      input.trim.drop(3).split("=", 2).map(_.trim) match {
        case Array("") => // "set"
          SetCommand(None, None)
        case Array(key) => // "set key"
          SetCommand(Some(key), None)
        case Array(key, value) => // "set key=value"
          SetCommand(Some(key), Some(value))
      }
    } else {
      // this is the core of SqlParser
      phrase(query)(new lexical.Scanner(input)) match {
        case Success(r, x) => r
        case x => sys.error(x.toString)
      }
    }
  }
```

parseSql implements a **SqlParser**, this Parser calls its `apply`

SqlParser class graph

![](D:\ideaprojects\yanjiushengbiji\spark\spark sql\csdn-second\sqlparser2.png)

SqlParser extends Parsers, now SqlParser has word segmentation func and parsing combiner func

```scala
 /** A parser generator delimiting whole phrases (i.e. programs).
   *
   *  `phrase(p)` succeeds if `p` succeeds and no input is left over after `p`.
   *
   *  @param p the parser that must consume all input for the resulting parser
   *           to succeed.
   *  @return  a parser that has the same result as `p`, but that only succeeds
   *           if `p` consumed all the input.
   */
  def phrase[T](p: Parser[T]) = new Parser[T] {
    def apply(in: Input) = lastNoSuccessVar.withValue(None) {
      p(in) match {
      case s @ Success(out, in1) =>
        if (in1.atEnd)
          // if input stream overs, return s (Success)
          // this s include SqlParser's parsed output
          s
        else
            lastNoSuccessVar.value filterNot { _.next.pos < in1.pos } getOrElse Failure("end of input expected", in1)
        case ns => lastNoSuccessVar.value.getOrElse(ns)
      }
    }
  }
```

Phrase reads input characters cyclically, if in doesn't arrive the last character, continue to parse the parser, until the last character

```scala
/** The success case of `ParseResult`: contains the result and the remaining input.
   *
   *  @param result The parser's output
   *  @param next   The parser's remaining input
   */
  case class Success[+T](result: T, override val next: Input) extends ParseResult[T] {
```

Success encapsoles current parser's parsed result and not-parsed result

### core of SQL Parser

phrase recieve two parameters:

* query, parsing rule with pattern, returns LogicalPlan
* lexical

the process of SqlParser parsing:

* lexical word scan input recieve SQL keyword
* query pattern parses SQL that conforms to the rules

#### lexical keyword

```scala
protected case class KeyWord(str: String)
```

```scala
protected val ALL = Keyword("ALL")
  protected val AND = Keyword("AND")
  protected val AS = Keyword("AS")
...
```

according to these keywords, reflect, generate a **SqlLexical**

```scala
override val lexical = new SqlLexical(reserveWords)
```

SqlLexical use its Scanner(Parser) to read input and then transfer to **query** 

#### query

query is Parser[LogicalPlan] and some connect symbol

```scala
protected lazy val query: Parser[LogicalPlan] = (
    select * (
        UNION ~ ALL ^^^ { (q1: LogicalPlan, q2: LogicalPlan) => Union(q1, q2) } |
        UNION ~ opt(DISTINCT) ^^^ { (q1: LogicalPlan, q2: LogicalPlan) => Distinct(Union(q1, q2)) }
      )
    | insert | cache
  )
```



```scala
protected lazy val select: Parser[LogicalPlan] =
    SELECT ~> opt(DISTINCT) ~ projections ~
    opt(from) ~ opt(filter) ~
    opt(grouping) ~
    opt(having) ~
    opt(orderBy) ~
    opt(limit) <~ opt(";") ^^ {
      case d ~ p ~ r ~ f ~ g ~ h ~ o ~ l  =>
        val base = r.getOrElse(NoRelation)
        val withFilter = f.map(f => Filter(f, base)).getOrElse(base)
        val withProjection =
          g.map {g =>
            Aggregate(assignAliases(g), assignAliases(p), withFilter)
          }.getOrElse(Project(assignAliases(p), withFilter))
        val withDistinct = d.map(_ => Distinct(withProjection)).getOrElse(withProjection)
        val withHaving = h.map(h => Filter(h, withDistinct)).getOrElse(withDistinct)
        val withOrder = o.map(o => Sort(o, withHaving)).getOrElse(withHaving)
        val withLimit = l.map { l => Limit(l, withOrder) }.getOrElse(withOrder)
        withLimit
  }
```

```sql
select  distinct  projections from filter grouping having orderBy limit.

select  game_id, user_name from game_log where date<='2014-07-19' and user_name='shengli' group by game_id having game_id > 1 orderBy game_id limit 50.
```

**projection** , is a expression, a Seq, returns an Expression, is a TreeNode in Catalyst

```scala
protected lazy val projections: Parser[Seq[Expression]] = repsep(projection, ",")
 
  protected lazy val projection: Parser[Expression] =
    expression ~ (opt(AS) ~> opt(ident)) ^^ {
      case e ~ None => e
      case e ~ Some(a) => Alias(e, a)()
    }
```

**from**, is a relations, can be a table in SQL

```scala
protected lazy val from: Parser[LogicalPlan] = FROM ~> relations
protected lazy val relation: Parser[LogicalPlan] =
    joinedRelation |
    relationFactor
 
  protected lazy val relationFactor: Parser[LogicalPlan] =
    ident ~ (opt(AS) ~> opt(ident)) ^^ {
      case tableName ~ alias => UnresolvedRelation(None, tableName, alias)
    } |
    "(" ~> query ~ ")" ~ opt(AS) ~ ident ^^ { case s ~ _ ~ _ ~ a => Subquery(a, s) }
 
   protected lazy val joinedRelation: Parser[LogicalPlan] =
     relationFactor ~ opt(joinType) ~ JOIN ~ relationFactor ~ opt(joinConditions) ^^ {
      case r1 ~ jt ~ _ ~ r2 ~ cond =>
        Join(r1, r2, joinType = jt.getOrElse(Inner), cond)
     }
```

```scala
case class Subquery(alias: String, child: LogicalPlan) extends UnaryNode {
  override def output = child.output.map(_.withQualifiers(alias :: Nil))
  override def references = Set.empty
}
```

### Conclution

sql文本作为输入，实例化了SqlParser，SqlParser的apply方法被调用，分别处理2种输入，一种是命令参数，一种是sql。对应命令参数的会生成一个叶子节点，SetCommand，对于sql语句，会调用Parser的phrase方法，由lexical的Scanner来扫描输入，分词，最后由query这个由我们定义好的sql模式利用parser的连接符来验证是否符合sql标准，如果符合则随即生成LogicalPlan语法树，不符合则会提示解析失败。

