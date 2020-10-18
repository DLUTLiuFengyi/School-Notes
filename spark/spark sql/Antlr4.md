## Catalyst - Anlrt4



The nodes of generated AST are all subclass of `ParseRuleContext`



### source code analysis 

#### entrance

```scala
def sql(sqlText: String): DataFrame = {
    // TODO 1. 生成LogicalPlan
    // sqlParser 为 SparkSqlParser
    val logicalPlan: LogicalPlan = sessionState.sqlParser.parsePlan(sqlText)
    // 根据 LogicalPlan
    val frame: DataFrame = Dataset.ofRows(self, logicalPlan)
    frame // sqlParser
  }
```

#### locate SparkSqlParser

SessionState

```scala
lazy val sessionState: SessionState = {
    parentSessionState
      .map(_.clone(this))
      .getOrElse {
        // 构建 org.apache.spark.sql.internal.SessionStateBuilder
        val state = SparkSession.instantiateSessionState(
          SparkSession.sessionStateClassName(sparkContext.conf),
          self)
        initialSessionOptions.foreach { case (k, v) => state.conf.setConfString(k, v) }
        state
      }
  }
```

```scala
private def sessionStateClassName(conf: SparkConf): String = {
    // spark.sql.catalogImplementation, 分为 hive 和 in-memory模式，默认为 in-memory 模式
    conf.get(CATALOG_IMPLEMENTATION) match {
      // hive 实现 org.apache.spark.sql.hive.HiveSessionStateBuilder
      case "hive" => HIVE_SESSION_STATE_BUILDER_CLASS_NAME 
      // org.apache.spark.sql.internal.SessionStateBuilder
      // SessionBuilder used to construct SessionState
      case "in-memory" => classOf[SessionStateBuilder].getCanonicalName 
    }
  }
```

```scala
/**
   * Helper method to create an instance of `SessionState` based on `className` from conf.
   * The result is either `SessionState` or a Hive based `SessionState`.
   */
  private def instantiateSessionState(
      className: String,
      sparkSession: SparkSession): SessionState = {
    try {
      // org.apache.spark.sql.internal.SessionStateBuilder
      // invoke `new [Hive]SessionStateBuilder(SparkSession, Option[SessionState])`
      val clazz = Utils.classForName(className)
      val ctor = clazz.getConstructors.head
      ctor.newInstance(sparkSession, None).asInstanceOf[BaseSessionStateBuilder].build()
    } catch {
      case NonFatal(e) =>
        throw new IllegalArgumentException(s"Error while instantiating '$className':", e)
    }
  }
```

BaseSessionStateBuilder.build

```scala
/**
   * Build the [[SessionState]].
   */
  def build(): SessionState = {
    new SessionState(
      session.sharedState,
      conf, // properties of SparkConf
      experimentalMethods,
      functionRegistry, // map of registration
      udfRegistration, // registry udf
      () => catalog, // SessionCatalog 
      sqlParser, // SparkSqlParser, call ASTBuilder to change sql into AST
      () => analyzer,
      () => optimizer,
      planner,
      streamingQueryManager,
      listenerManager,
      () => resourceLoader,// load jar or resources
      createQueryExecution,
      createClone)
  }
```

#### parsePlan

implementation is in parent class of SparkSqlParser: AbstractSqlParser 

```scala
/** Creates LogicalPlan for a given SQL string. */
    // TODO 根据 sql语句生成 逻辑计划 LogicalPlan
  override def parsePlan(sqlText: String): LogicalPlan = parse(sqlText) { parser =>
      val singleStatementContext: SqlBaseParser.SingleStatementContext = parser.singleStatement()
    astBuilder.visitSingleStatement(singleStatementContext) match {
      case plan: LogicalPlan => plan
      case _ =>
        val position = Origin(None, None)
        throw new ParseException(Option(sqlText), "Unsupported SQL statement", position, position)
    }
  }
```

the method behind `parse()` in first line is a recall func(回调函数), it is called by `parse()`

SparkSqlParser.parse

```scala
private val substitutor = new VariableSubstitution(conf) // 参数替换器

  protected override def parse[T](command: String)(toResult: SqlBaseParser => T): T = {
    super.parse(substitutor.substitute(command))(toResult)
  }
```

the substitutor is a parameter replacer, used for replacing the params of sql

now continue to see the parent class AbstractSqlParser.parse

```scala
protected def parse[T](command: String)(toResult: SqlBaseParser => T): T = {
    logDebug(s"Parsing command: $command")

    // 词法分析
    val lexer = new SqlBaseLexer(new UpperCaseCharStream(CharStreams.fromString(command)))
    lexer.removeErrorListeners()
    lexer.addErrorListener(ParseErrorListener)
    lexer.legacy_setops_precedence_enbled = SQLConf.get.setOpsPrecedenceEnforced

    // 语法分析
    val tokenStream = new CommonTokenStream(lexer)
    val parser = new SqlBaseParser(tokenStream)
    parser.addParseListener(PostProcessor)
    parser.removeErrorListeners()
    parser.addErrorListener(ParseErrorListener)
    parser.legacy_setops_precedence_enbled = SQLConf.get.setOpsPrecedenceEnforced

    try {
      try {
        // first, try parsing with potentially faster SLL mode
        parser.getInterpreter.setPredictionMode(PredictionMode.SLL)
        // 使用 AstBuilder 生成 Unresolved LogicalPlan
        toResult(parser)
      }
      catch {
        case e: ParseCancellationException =>
          // if we fail, parse with LL mode
          tokenStream.seek(0) // rewind input stream
          parser.reset()

          // Try Again.
          parser.getInterpreter.setPredictionMode(PredictionMode.LL)
          toResult(parser)
      }
    }
    catch {
      case e: ParseException if e.command.isDefined =>
        throw e
      case e: ParseException =>
        throw e.withCommand(command)
      case e: AnalysisException =>
        val position = Origin(e.line, e.startPosition)
        throw new ParseException(Option(command), e.message, position, position)
    }
  }
```

this method calls the api of ANLTR4 to change sql into AST, then calls `toResult(parser)`, the `toResult(parser)` is the recall func of parsePlan

before calling the `astBuilder.visitSingleStatement`, the AST has been built



### print the AST

#### change the source code

astBuilder.visitSingleStatement

```scala
override def visitSingleStatement(ctx: SingleStatementContext): LogicalPlan = withOrigin(ctx) {
    val statement: StatementContext = ctx.statement
    printRuleContextInTreeStyle(statement, 1)
    // 调用accept 生成 逻辑算子树AST
    visit(statement).asInstanceOf[LogicalPlan]
  }
```

before using visitor mode to visit AST node to generate UnResolved LogicalPlan, define a method to print the AST generated just now

```scala
/**
   * 树形打印抽象语法树
   */
  private def printRuleContextInTreeStyle(ctx: ParserRuleContext, level:Int): Unit = {
    val prefix:String = "|"
    val curLevelStr: String = "-" * level
    val childLevelStr: String = "-" * (level + 1)
    println(s"${prefix}${curLevelStr} ${ctx.getClass.getCanonicalName}")
    val children: util.List[ParseTree] = ctx.children
    if( children == null || children.size() == 0) {
      return
    }
    children.iterator().foreach {
      case context: ParserRuleContext => printRuleContextInTreeStyle(context, level + 1)
      case _ => println(s"${prefix}${childLevelStr} ${ctx.getClass.getCanonicalName}")
    }
  }
```

#### examples

```sql
select name from student where age > 18
```

```shell
|- org.apache.spark.sql.catalyst.parser.SqlBaseParser.StatementDefaultContext
|-- org.apache.spark.sql.catalyst.parser.SqlBaseParser.QueryContext
|--- org.apache.spark.sql.catalyst.parser.SqlBaseParser.SingleInsertQueryContext
|---- org.apache.spark.sql.catalyst.parser.SqlBaseParser.QueryTermDefaultContext
|----- org.apache.spark.sql.catalyst.parser.SqlBaseParser.QueryPrimaryDefaultContext
|------ org.apache.spark.sql.catalyst.parser.SqlBaseParser.QuerySpecificationContext
|------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.QuerySpecificationContext
|------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.NamedExpressionSeqContext
|-------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.NamedExpressionContext
|--------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.ExpressionContext
|---------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.PredicatedContext
|----------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.ValueExpressionDefaultContext
|------------ org.apache.spark.sql.catalyst.parser.SqlBaseParser.ColumnReferenceContext
|------------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.IdentifierContext
|-------------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.UnquotedIdentifierContext
|--------------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.UnquotedIdentifierContext
|------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.FromClauseContext
|-------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.FromClauseContext
|-------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.RelationContext
|--------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.TableNameContext
|---------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.TableIdentifierContext
|----------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.IdentifierContext
|------------ org.apache.spark.sql.catalyst.parser.SqlBaseParser.UnquotedIdentifierContext
|------------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.UnquotedIdentifierContext
|---------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.TableAliasContext
|------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.QuerySpecificationContext
|------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.PredicatedContext
|-------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.ComparisonContext
|--------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.ValueExpressionDefaultContext
|---------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.ColumnReferenceContext
|----------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.IdentifierContext
|------------ org.apache.spark.sql.catalyst.parser.SqlBaseParser.UnquotedIdentifierContext
|------------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.UnquotedIdentifierContext
|--------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.ComparisonOperatorContext
|---------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.ComparisonOperatorContext
|--------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.ValueExpressionDefaultContext
|---------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.ConstantDefaultContext
|----------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.NumericLiteralContext
|------------ org.apache.spark.sql.catalyst.parser.SqlBaseParser.IntegerLiteralContext
|------------- org.apache.spark.sql.catalyst.parser.SqlBaseParser.IntegerLiteralContext
|---- org.apache.spark.sql.catalyst.parser.SqlBaseParser.QueryOrganizationContext
```


