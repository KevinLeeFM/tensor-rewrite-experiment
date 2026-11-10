# First source-case batch: contract dependencies

Source revision: e58e523b11f1fde802a493a776d158007486e1bf.
Generated record: `census/simple-cases.json`; generator:
`tools/extract_simple_cases.py`. These are source schemas, not 26 fully split
verification obligations. No independent reviewer or accepted proof is recorded.

## Traced helper behavior

- `SameShape`, algebraic_simplifier.cc:623–634: selects ShapeUtil::Equal when
  layout-sensitive and ShapeUtil::Compatible otherwise. A shape-only theorem
  must state which relation it provides.
- `ReplaceInstructionIfCompatible`, :861–880: refuses existing control
  predecessors, checks SameShape, calls replacement preserving sharding and
  frontend attributes, and returns the actual replacement outcome.
- `DfsHloRewriteVisitor::ReplaceInstruction`,
  xla/hlo/ir/dfs_hlo_visitor_with_default.h:384–413: the four-argument overload
  relays control dependencies, removes unused operands and marks change only
  from the returned outcome. The simpler overload defaults preserve_sharding
  to false. Do not transfer compatibility-helper guard claims to direct calls.
- `IsAll`, algebraic_simplifier.cc:93–132: unwraps eligible constant-producing
  operations before testing Literal::IsAll. It is not just a literal syntax
  matcher. A value-level uniformity lemma must justify each unwrapping step.
- `TrySimplifyTautologicalCompare`, :1264–1307: each conjunct permits either
  LT(variable, constant) or GT(constant, variable); constants must be effective
  S32 scalars and variable pointers must match. Four orientation schemas share
  one construction site. This helper is reached from HandleAnd after its
  earlier successful simplifications have been excluded.

## Residual contracts before accepting these source cases

1. Trace HloComputation::ReplaceInstruction/ReplaceWithNewInstruction and
   HloInstruction::Identical, including sharding, control dependencies and
   observable metadata. Headers alone do not establish the implementation.
2. Split the legal dtypes of Boolean/bitwise operations and arithmetic negation;
   establish NaN/exceptional-value observations instead of assuming bit equality.
3. Trace MakeScalarLike, BroadcastZeros, IsAll and matcher details; retain shape,
   scalar/broadcast and dynamic-dimension behavior in statements.
4. Map each branch to its precise site and explain non-replacement sites. The
   current handler-level candidate links deliberately overapproximate this map.
5. Independently review the source mappings before freezing any obligations or
   counting them in accepted coverage.

The batch makes progress on source formalization. It does not close the census,
the pilot semantic-contract gate or graph-replacement correctness.
