### Process

* SQL   ->   [Antlr4]   -> Unresolved Logical Plan

  1. antlr4: sql -> syntax tree
  2. visitor mode in antlr4: syntax tree -> logical plan

  class AstBuilder (in step 2)

  * from
  * withQuerySpecification [use scala pattern matching]: select, filter, group by, having

*   Unresolved Logical Plan   ->   [analyzer]   ->   (Resolved) Logical Plan

  Unresolved represents we don't know whether src, schema exist, don't know the type of one col or whether the col exists.