可以从Apache Calcite中得到的启示：

Query Optimizer可以获得Pluggable Rules（从经验中总结的优化策略），以及Metadata Providers提供的 **行数、table哪一列是唯一列、计算RelNode树中执行subexpression cost的函数**