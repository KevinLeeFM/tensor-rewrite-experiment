# Ordered source paths and the NaN comparison boundary

XLA e58e523b11f1fde802a493a776d158007486e1bf; Lean4.35.0/Std only.
Canonical algebraic_simplifier.cc is unchanged. Source acceptance remains zero;
semantic N/F remain unfrozen. This milestone prioritizes the incomplete source
census rather than treating more logical value laws as whole-file coverage.

## Inspected paths

`census/ordered-source-paths.json` reconciles41 existing provisional schemas
through the complete Broadcast, Compare and Pad bodies and four directly relevant
helpers. It records ordered stages, exits, continuation and pre-terminal effects:

- Broadcast's original-value recovery table is modified before replacement;
  sinking can affect multiple users before an error. The scalar-user loop returns
  on its first qualifying user, and returns even when none qualifies; later Iota,
  composition and degenerate-axis branches cannot follow a scalar operand.
- Compare's unsigned/nonnegative/self/PRED/mask branches return immediately.
  Its final Maximum/Minimum GT cases mutate an operand of the same Compare and
  mark changed only after successful replacement. A matching lhs Maximum takes
  precedence over the rhs Minimum alternative even if no operand pointer matches.
- Pad's all_zero flag concerns edge padding only. A failed compatible replacement
  continues; most returning replacement branches do not. Broadcast projection
  mutates shape, dimensions, sharding and layout before constructing the final
  replacement. Negative-padding lowering can allocate and edit type/layout before
  a later status/shape check fails; the handler shows no rollback.

These are source-inspected path models, not a complete typed/alias/frame contract
or independent semantic acceptance. Runtime dynamic sizes, numerical permissions,
helper composition and API status/skip/root/uses/control/metadata effects remain
explicit obligations. The central review ledger links the new path stages and
independent findings instead of leaving them in an isolated report.

## Concrete nonnegative-helper boundary

`IsNonNegative:540–607` accepts floating Abs, Exp, self-Multiply and Maximum with
a recognized nonnegative operand without ruling out NaN. `HandleCompare:5942–5947`
then folds GE/LE against zero to true. The corresponding LT/GT folds return false.
The name of the helper cannot serve as a proof that an ordinary ordered >=0
comparison returns true for every represented value.

`comparison_util.h:90–99` documents floating default partial ordering; explicit
total and weak ordering are separate. Its comparator dispatch and
`HloEvaluator::HandleCompare:1658–1686` are pinned in
`census/ordered-compare-contract.json`. No assertion that these different orderings
have the same NaN behavior is made.

`reports/compare-nonnegative-replay-v1/result.json` records60 exact-source runs:
5 producer forms ×4 directions ×3 modes (control/initialized handler/whole pass).
Four producer forms are Abs, Exp, self-Multiply and Maximum(input,zero); the fifth
is an unrecognized direct parameter control. Each has six cells: quiet NaN,-1,0,1,
positive infinity,negative infinity. All input and transformed HLO graphs verify.
Module CPU fast math and pass fast math are disabled; NaNs/Infs are honored and
the slow evaluator is explicit. Handler priming suppresses only Compare and must
leave both status and graph text unchanged before the original handler is called.

There are16 Boolean-changing runs: each recognized producer, GE/LE direction,
and handler/pass mode changes the NaN cell from false to true. The five other
cells agree. Control mode, LT/GT and direct-parameter profiles provide negative
controls. This is a Boolean value change, unlike the earlier signed-zero-only
bit difference. These are host-evaluator/source-path observations; no compiled
backend experiment or complete adopted source-observation contract is claimed.

## Kernel certificates and artifact burden

`OrderedCompareProfile.lean` defines a binary32 NaN by exponent/fraction bits and
only the necessary ordinary ordered-comparison condition: either NaN operand
requires false. It does not implement all IEEE arithmetic or the producer ops.
Six certificates prove consistency of false, incompatibility of true for either
NaN side, and concrete quiet-NaN witnesses. All six have empty axiom dependencies.
A Lean negative control rejects the contrary true-result claim. Model probes
compute both true-result incompatibilities and the allowed false result.

| Category | Previous | Added | Current |
| --- | ---: | ---: | ---: |
| S, semantics | 706 | 18 | 724 |
| H, support | 866 | 0 | 866 |
| R, value/context rules | 691 | 0 | 691 |
| A, integration | 30 | 1 | 31 |
| C, certificates | 254 | 20 | 274 |
| Total custom Lean | 2547 | 39 | 2586 |

The77 value laws and86 support lemmas are unchanged: refutation certificates do
not inflate preservation-rule counts. Tests/audits and non-Lean review/harness
work remain separately visible.39 lines measures the additional Lean artifact,
not the full cost of source review or a model-independent difficulty bound.

## Independent review and next dependency

`reviews/results/census-pilot-v1-large-handlers-codex-reviewer.md` independently
reads Add, Copy, Concatenate, Divide and Gather (1087 body lines,60 schemas,
22 selected direct local edges/11 distinct helper names, plus relevant transitive
helpers). This first supplement brings independent full-body reading to48/58 Handle-prefixed
functions; this is reading extent, not semantic closure of those functions.
The original report remains unchanged. Its two concrete value candidates are:

1. Scatter reducer matching accepts Add(Parameter(),Parameter()) without checking
   parameter roles. A repeated parameter0 reducer can make an Add/Scatter rewrite
   change [7,4] to [8,4] in a small mathematical example.
2. Gather select-chain unrolling at configurable threshold129 can construct a
   signed s8 literal128 as -128, selecting label128 for index0 instead of label0.
   Default-threshold and wider-index controls are required.

These remain independently source-inspected/mathematical candidates, not native
or Lean-confirmed source defects. Concatenate allocation before a rejected
compatibility attempt is a separate API/frame/changed-flag outcome candidate,
not a tensor-value claim. `census/source-review-findings.json` preserves exact
validation levels and links all candidates to existing schemas. Native replay
and certificates for them are the next diagnosis dependency; none is dropped
because the source premise is awkward. The completed shape-handler supplement independently reads Broadcast, Compare,
Pad, Reshape and Transpose (1116 body lines,63 schemas,41 selected direct local
edges/19 helper names), bringing full-body reading to53/58. Five indexing/reduction
bodies remain. It independently supports the partial-order NaN concern and
corrects the first report's blanket sorted/unique Broadcast advisory: client
BroadcastInDim, optional verifier ordering and the general source contract are
different surfaces. The bounded logical BroadcastAxes was not strengthened.

The supplement also records a conditional Reshape/DUS obligation: deleting a
unit base axis when the update extent is zero can construct an invalid update
reshape. Ordinary full-pass DUS cleanup may remove that case first; async
reachability is unverified. This is not claimed as an ordinary pass defect.
It is recorded with that limitation in the finding ledger. Reading all of these
bodies still does not close their typed helper/API/observation semantics.

## Validation

All59 Python/evidence tests and the full checkpoint pass. Controls reject schema
omissions, an invented denominator, erasing Pad's continuation, treating NaN-
capable recognition as an unconditional ordered predicate, erased NaN truth
changes, omitted producer profiles and false source acceptance. The fresh Lean
replay at `reports/ordered-comparison-clean-replay.json` preserves every earlier
axiom set, measurement and model probe. Snapshot:
`snapshots/ordered-comparison-pilot-v1.zip`, SHA256
4682254e95d2d851ee4e041561f1d46507b5d193c9d58e5c3cf1dc00a1d672b4.
Later source-policy slice pins do not change those replayed Lean bytes.


## New continuation candidate from the remaining review

Inspection of `HandleDynamicSlice:8328–8433` identifies a distinct original-graph
partition omitted by the current direct-nested LHS. The Iota probe recognizes
Multiply(x,Broadcast(scalar)), assigns local operand=x, then leaves that binding
in place if x is not Iota. The later nested-DynamicSlice branch tests the changed
local variable, so an original DS(Multiply(innerDS(x),Broadcast(m)),outerStart)
may be treated as direct nested DS and lose the multiplication.

A source-inspected mathematical witness is x=[1..10], inner size6/start1, outer
size1/start2, runtime scalar7: original28 versus proposed replacement4. Use
runtime start parameters or disable_dynamic_slice_to_slice_conversion to bypass
the earlier constant-index return. The element type S32 and rank1/size1 probe,
Broadcast at Multiply operand1, fit checks and earlier guards are material.
The root independently inspected this continuation after the reviewer reported
it. Native/Lean confirmation and final review supplement are still pending.
The existing `HandleDynamicSlice/nested` theorem concerns the direct-nested
logical expression and cannot discharge this additional original-graph path.
This is a semantic-partition gap despite complete lexical-site binding; correct
and split the extraction after replay, before freezing any N.
