---

### Data

Read the source and return DataQuanta[Record]

**Record.java** 

Actual data

**RecordType.java**

A specify BasicDataUnitType for Records, it adds schema information

```java
Operator.java
/**
 * Connect an output of this operator to the input of a second operator.
 *
 * @param thisOutputIndex index of the output slot to connect to
 * @param that            operator to connect to
 * @param thatInputIndex  index of the input slot to connect from
 */
@SuppressWarnings("unchecked")
default <T> void connectTo(int thisOutputIndex, Operator that, int thatInputIndex) {
    final InputSlot<T> inputSlot = (InputSlot<T>) that.getInput(thatInputIndex);
    final OutputSlot<T> outputSlot = (OutputSlot<T>) this.getOutput(thisOutputIndex);
    outputSlot.connectTo(inputSlot);
}
```

```java
OutputSlot.java
/**
 * Connect this output slot to an input slot. The input slot must not be occupied already.
 *
 * @param inputSlot the input slot to connect to
 */
public void connectTo(InputSlot<T> inputSlot) {
    this.occupiedSlots.add(inputSlot);
    inputSlot.setOccupant(this);
}
```

###  Return Thing

Return DataQuantaBuilder [DataQuanta[Record]]

.readTable 

Calls a method of DataQunataBuilder names "asRecords". Returns a RecordDataQuantaBuilder(DataQuantaBuilder for the Records in the table)

.filter

Return a FilterDataQuantaBuilder



### SQL clause

PredicateDescriptor.java

udf - SerializablePredicate

sqlUdf - String

this.sqlImplementation = sqlUdf



---

JavaApiTest.java

testSqlOnJava

```java
new RheemContext(this.sqlite3Configuration) 
    // rheemCtx RheemContext@1465
    // sqlite3Configuration "Configuration[file:/.../rheem.properties]"
.with(Java.basicPlugin())
.with(Sqlite3.plugin());
```

1. RheemContext.java

   2. with: plugin Sqlite3Plugin@1466

      register: plugin Sqlite3Plugin@1466

      3. Plugin.java

         configure: configuration "Configuration[RheemContext(file:/...)]"

         4. ExplicitCollectionProvider.java

            addAllToWhitelist: values size=2

            addAllToBlacklist: values size=0

            addAllToWhitelist: values size=2

            addAllToBlacklist: values size=0

            addAllToWhitelist: values size=2

            addAllToBlacklist: values size=0

            5. Sqlite3Plugin.java

               setProperties: configuration "Configuration[RheemContext(file:/...)]"

   

```java
JavaPlanBuilder builder = new JavaPlanBuilder(rheemCtx, "testSqlOnJava()");
// rheemCtx RheemContext@1465
```

6. JavaPlanBuilder.scala: rheemCtx RheemContext@1465, jobName "testSqlOnJava()"

   protected planBuilder null, rheemCtx RheemContext@1465, jobName "testSqlOnJava()"

   7. PlanBuilder.scala: jobName "test..."

      PlanBuilder

      sinks "ListBuffer", size=0

      A LITTLE LONG TIME

      udfJars null -> "HashSet" size=0

      A LITTLE LONG TIME

      RflectUtils.getDeclaringJar

      8. ReflectUtils.java

         getDeclaringJar: object PlanBuilder@1554

         getDeclaringJar: cls "class org....PlanBuilder"

         ​	location "file:/.../rheem-with-arrow/rheem-api/target/classes/"

         ​	uri "file:/.../rheem-with-arrow/rheem-api/target/classes/"

         ​	path "file:/.../rheem-with-arrow/rheem-api/target/classes/"

```java
final Collection<String> outputValues = builder
    // builder JavaPlanBuilder@1551
```

9. JdbcTableSource.java

10. Sqlite3TableSource.java

    con: tabelName "customer", columnNames {"name""age"}

    11. JdbcTableSource.java

        con: tableName "customer", columnNames {"name""age"}

        12. TableSource.java

            con: 

            con: Warp String[] to DataSetType. tableName "customer", type "DataSetType[Record[name, age]]"

            13. UnarySource.java

                con: type "DataSetType[Record[name, age]]"

                con: type "DataSetType[Record[name, age]]", ... false

                14. OperatorBase.java

                    con: numInputSlots 0, numOutputSlots 1, Broad... false

                    members: isAu... false, epoch 0, inputSlots InputSlot[0]@1904, outputSlots  outputSlot[1]@1905, targetPlatforms null

                    con: cardinalityEstimators CardinalityEstimator[1]@2179

                15. new OutputSlot<>("out", this.type): type "DST[RT[name, age]]"

                    OutputSlot.java

                    con: name "out", owner "Sqlite3TableSource[0->1, id=565f390]", type "DST[RT[name, age]]"

                    16. Slot

                        con:

                        members:

                        con: name "out", owner "...", type "DST[RT[name, age]]"

                    17. occupiedSlots null

```java
.readTable(new Sqlite3TableSource("customer", "name", "age"))
```

18. JavaPlanBuilder.scala

    def readTable: source "Sqlite3TableSource[0->1, id=565f390]"

    def createSourceBuilder: source "Sqlite3TableSource[0->1, id=565f390]" 24LATER builder UnarySourceDataQuantaBuilder@2268, source "Sqlite3TableSource[0->1, id=565f390]"

     19. DataQuantaBuilder.scala

         UnarySourceDataQuantaBuilder: source "Sqlite3TableSource[0->1, id=565f390]"

         ​	BasicDataQuantaBuilder

         ​	broadcasts "ListBuffer" size=0

         ​	targetPlatforms "ListBuffer" size=0

         ​	outputTypeTrap null

         ​	def getOutputTypeTrap = new TypeTrap

          	20. TypeTrap.scala

    BEGIN SWITCH DATASETTYPE

    21. package.scala

        object api

        def dataSetType: classTag "org...data.Record"

        22. DataSetType.java

            createDefault: dataUnitType "BasicDataUnitType[Record]"

            con: dataUnitType "BasicDataUnitType[Record]"

    23. DataSetType.java

        equals: o "DST[BDUT[R]]", dataUnitType "BDUT[Void]", that "DST[BDUT[R]]"

        24. BasicDataUnitType.java

            equals: o "BDUT[R]", typeClass "class java.lang.Void", that "BDUT[R]"

    25. SECOND CASE DataQuantaBuilder.scala

        def withOutputType: outputType "DST[BDUT[R]]"

        26. TypeTrap.scala

            def dataSetType_= : dst "DST[BDUT[R]]"

            GO BACK TO testSqlOnJava 

NOW WE HAVE:

sqlite3Configurtation

```java
.filter(r -> (Integer) r.getField(1) >= 18).withSqlUdf("age >= 18").withTargetPlatform(Java.platform())
```

**r -> (Integer) r.getField(1) >= 18**

LONG TIME LATER, NOW APPEAR DOZENS THREADS:

Main thread sank to the bottom, it remains RheemContext@1465, JavaPlanBuilder@1551. The top of this stack is lambda thread, it remains r={Record@3402}"Record[John, 20]". 

The number below starting from 1 represents the level of the stack(Beginning from the bottom).

1. DataQuantaBuilder.scala

   def collect

   2. DataQuanta.scala

      def collect --this.planBuilder.buildAndExecute()-- : collectot size=0, sink "LocalCallBackSink[Collect()]"

      3. PlanBuilder.java

         def buildAndExecute: plan RheemPlan@3438

         4. RheemContext.java

            execute90: jobName "testSqlOnJava()", rheemPlan RheemPlan@3438, udfJars {}

            execute102:  jobName "testSqlOnJava()", monitor null, rheemPlan RheemPlan@3438, udfJars {}

            5. Job.java

               execute(): super.execute()

               6. OneTimeExecutable.java

                  execute

                  

                  tryExecute

                  7. Job.java

                     doExecute: 

                     executionPlan ExecutionPlan@3532

                     optimizationRound "TimeMeasureMent[Optimization, 0...891, 3 subs]"

                     experiment "Experiment[unknown, 0 tags, 3 measurements]"

                     monitor DisabledMonitor@3477, configurtation "Configuration[testSqlOnJava()]", runId "1"

                     logger "...SimpleLogger(...Job)"

                     executionPlan ExecutionPlan@3532, executionId 0

                     

                     execute --isExecutionComplete...--: 

                     executionPlan ExecutionPlan@3532, executionId 0

                     currentExecutionRound "TimeMeasurement[Execution 0,0..0,1subs]", executionRound "TimeMeasurement[Execution,0..0,1subs]", executionId 0

                     configuration "Configuration[testSqlOnJava()]"

                     executionPlan ExecutionPlan@3532

                     currentExecutionRound "TimeMeasurement[Execution 0,0...0,1subs]"

                     crossPlatformExecutor CrossPlatformExecutor@3468

                     8. CrossPlatformExecutor.java

                        executeUntilBreakpoint: executionPlan ExecutionPlan@3532, optimizationContext DefaultOptimizationContext@3466

                        

                        runToBreakPoint --this.executeSingleStage--: 

                        startTime...

                        numPriorExecutedStages 0, completedStages size=1

                        isB... false

                        stageActivator CrossPlatformExecutor$StageActivator@3570, activatedStageActivators size=0

                        

                        executeSingleStage --this.execute--: sA CrossPE$SA@3570

                        execute360 --executor.execute()--: 

                        sA CrossPE$SA@3570

                        stage "ExecutionStage[T[SqlToStream[convert out@Sqlite3TableSource[0->1, id=565f390]]]]"

                        optimizationC DefaultOptimizationContext@3466, sA CPE$SA@3570

                        instrumentationStrategy OutboundInstrumentationStrategy@3561

                        executor "JavaExecutor[1]"

                        logger "...SL(CPE)"

                        

                        9. PushExecutorTemplate.java

                           execute43 --stageExecution.executeStage()--: 

                           stage "ExecutionStage[T[SqlToStream[convert out@Sqlite3TableSource[0->1, id=565f390]]]]"

                           optimizationC DefaultOptimizationContext@3466

                           executionStage CrossPlatformExecutor@3468

                           stageExecution PushExecutorTemplate$StageExecution@3604

                            

                           executeStage: executionState CrossPE@3468

                           10. OneTimeExecutable.java

                               execute

                               

                               tryExecute

                               11. PushExecutorTemplateStage.java$StageExecution

                                   doExecute: readyActivators size=0

                                   

                                   execute:

                                   readyActivator PushExecutorTemplate$TaskActivator@3701

                                   task "[JavaLocalCallbackSink[collect()]]"

                                   isREE true, terminalTasks size=1

                                   

                                   PushExecutorTemplateStage.java

                                   execute: taskActicator PushExecutorTemplate$TaskActivator@3701

                                   12. JavaExecutor.java

                                       execute --results=cast(...)--: task "T[JavaLocalCallbackSink[collect()]]"

                                       inputChannelInstances size=1

                                       producerOperatorContext "OperatorContext[JavaLocalCallbackSink[collect()]]"

                                       outputChannelInstances ChannelInstance[0]@3717

                                       13. JavaLocalCallbackSink.java

                                           evaluate --(JavaChannelInstance).provideStream--:

                                           inputs ChannelInstance[1]@3726

                                           outputs ChannelInstance[0]@3717

                                           executor "JavaExecutor[1]"

                                           operatorContext "OperatorContext[JavaLocalCallbackSink[collect()]]"

14. Record.java

    getField: index 1, values Object[2]@3407

15. ProjectDescriptor.java$RecordImplementation

    apply: input "Record[John, 20]", projectedFields Object[1]@3796, i 0, fieldIndex 0

    16. Record.java

        getField: index 0, values Object[2]@3407

    projectedFields Object[1]@3796

    17. Record.java

        con: values null, values Object[1]@@3796

```java
.map(record -> (String) record.getField(0)) // record "Record[John]"
```

18. Record.java

    getField: values Object[1]@@3796

19. SqlToStreamOperator.java

    THIS TIME, THIS THREAD'S VARIABLES:

    this = {SqlToStreamOperator$ResultSetIterator@3816}

    ​	resultSet={JDBC4ResultSet@3818}

    ​	next={Record@3817}"Record[Timmy, 16]"

    hasNext: next "Record[Timmy, 16]"

    $ResultSetIterator

    next: next "Record[Timmy, 16]"

    20. moveToNext: resultSet JDBC4ResultSet@3818

        next "Record[Timmy, 16]"

        recordWidth 2

        values Object[2]@3843, i 0

        values Object[2]@3843, i 1

        21. Record.java: values Object[2]@3843

            con

    moveToNext: next "Record[Evelyn, 35]"

22. StreamChannel.java

    NOW THIS THREAD HAS VARIABLES:

    this={StreamChannel$Instance@3879}"*StreamChannel[T[SqlToStream[convert out@Sqlite3TableSource[0->1, id=565f390]]]->[T[JavaFilter[1->1,id=616ac46a]]]]"

    dataQuantum={Record@3817}"Record[Timmy,16]"

    this.cardinality=1

    

    accept: stream ReferencePipeline$2@3880, dataQuantum "Record[Timmy, 16]", cadinality 1->2

```java
.filter(r -> (Integer) r.getField(1) >= 18)
```

23. Record.java

    getField: index 1, values Object[2]@3821 

24. SqlToStreamOperator.java

    hasNext: next "Record[Evelyn, 35]"

    $ResultSetIterator

    next: next "Record[Evelyn, 35]"

    25. moveToNext

        