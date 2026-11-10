# Frozen-v1 arithmetic source normalization

This companion indexes `census-pilot-v1-arithmetic-source-normalization.json`.
It records all **85 exact frozen arithmetic IDs** across HandleAdd, HandleDivide,
HandleMaximum, HandleMinimum and HandleCompare. Every entry has source spans,
ordered predecessor-stage constraints, actual captures, ordered construction or
operand writes, terminal/continuing outcomes and shared API contract references.
The JSON includes 58 ordered stages, 25 shared contracts and 250 exact source
excerpts with SHA256 hashes. Structural checks confirmed all85 unique IDs in
frozen order and every span/reference against the extracted source.

All five bodies and listed local/matcher/API contracts were independently reread.
The artifact records local source paths under explicit symbolic predicate and
constructor boundaries; it does not assert semantic correctness, source/proof
acceptance, whole-pass reachability, or freeze N/F. No native run or later live
artifact was used. All prior reports are preserved.

The actionable reconciliation points are:

- Add's later factor/Scatter paths retain **original operand0/operand1 order**.
  Failed whole Match does not capture; successful partial-update matching returns.
  Single-lhs Scatter constructs Add(lhs base, original rhs), correcting misleading
  frozen RHS prose. Scatter reducer roots can repeat parameter roles.
- AnyOrder chooses an orientation before later equality/numerical/evaluator tests.
  Those later failures do not retry alternate captures. The JSON records exact
  selection priority for factor/cancellation/clamp/partial-update variants.
- Divide constant-denominator dispatch returns even when the literal type dispatch
  performs no rewrite. It does not fall through to later Divide branches.
- New-node replacement may insert then skip on controls; sequential Scatter writes
  can survive a later error. These are explicit shared API/path outcomes.
- Compare's IsNonNegative guard has no non-NaN/order-type condition. Recording the
  actual source predicate is sufficient for enumeration; correctness comes later.

There are no silently omitted or incomplete local case entries. Shared creation
routines absent from the frozen packet remain explicit declared call boundaries:
MakeBinaryHlo, MakeConcatHlo and MakeScalarLikeFromLiteral. Expansion would require
separately pinned definitions if the integrator chooses that wider source scope.
The virtual UpdateLayout extension point retains its pinned default behavior and
backend override boundary. The other402 frozen IDs and global caller/fixedpoint/effect closure remain outside
this bounded batch. The85 rows are source variants, not a proposed denominator.
