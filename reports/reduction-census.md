# Reduce and ReduceWindow source census

Source pin: e58e523b11f1fde802a493a776d158007486e1bf.
Target: xla/hlo/transforms/simplifiers/algebraic_simplifier.cc.
Data/extractor: census/reduction-cases.json; tools/extract_reduction_cases.py.

## Coverage and declaration reconciliation

The batch records 60 schemas: HandleReduce23, HandleReduceWindow31,
BroadcastReduce2, ReplaceReduceWithReshape2, MergeReduces1 and
ReorderReduceDotToDotReduce1. All 34 executable replacement-related calls within
these six methods have bindings. Caller/helper and lambda-body records overlap;
they are not a disjoint rewrite count. Eight helper behavior records are source-
inspected and still pending independent semantic review.

At this batch's checkpoint the whole map had 412 schema bindings, 309 executable replacement-related
sites bound, 30 remaining candidates and five declaration-only exclusions. The
five declarations were already recognized as noncalls by the syntax inventory;
the map now partitions them explicitly instead of leaving them among residual
rewrite candidates. Exact source identity and a matching error-free syntax view
are required for exclusion. Moving a real residual call into that partition is
rejected. No complete semantic denominator or source acceptance is claimed.

## Algebraic premises belong to the operator contract

The pinned docs/operation_semantics.md:3831–3874 and :4112–4169 require identity
initial values and allow reassociation for Reduce/ReduceWindow. The matching
[official operation reference](https://openxla.org/xla/operation_semantics#reduce)
was also checked. sources/reduction-contract-manifest.json hashes the pinned
document, so later contract work need not depend on the mutable website.

Thus, discarding a nonidentity initializer is not automatically a counterexample
within the documented XLA domain. Conversely, a shape-valid HLO graph is not by
itself evidence that its reducer/initializer satisfies the semantic premises.
Identity needs a precise admissible domain; the approximate associativity prose
needs an independently grounded floating observation relation. Neither may be
replaced by an axiom stating that each desired source rewrite is valid.

Tuple reducers can couple components. Argmin/argmax additionally depend on NaN
tests, extrema, index ties and Iota ranges. Source matcher classifications do not
prove the required algebraic laws on all scalar/tuple values. IsScalarConstantInf
and IsScalarConstantNegInf accept native max/lowest values when the format lacks
infinity; treating their names as floating-only guards would silently drop types.

## Reduce source details

Empty input/result uses representative tuple shapes and constructs one broadcast
per init value. Equal input/result element count delegates to reshape construction,
discarding the reducer under the documented identity expectation. Layout-sensitive
mode adds a physical-bitcast check, while most subsequent transformations require
layout-insensitive mode and eventually a single-output result.

The negate-sum path snapshots old users before creating Negate(reduce), then
replaces only that saved user set. This avoids treating the newly created user as
an old use and creating a cycle. Source records group both operand and use writes.

Transpose and reshape movement retain axis renumbering, user-count/profitability
options and output permutation branches. Concat reduction creates partial reduces
and a left-associated Map chain; repeated initializer use needs its identity law.
Dot batch axes can become contracting axes, with optional residual reductions.
Other paths reuse an existing argmin/argmax result, apply an idempotent scalar
reducer once, commute reduction over original broadcast axes or replace replicated
sum axes with a finite repetition multiplier.

ReductionComputationsEquivalent checks object identity or matching two-parameter
Add/Multiply/And/Or categories. It does not by itself establish equivalence for
every floating observation. MergeReduces sorts copied axis lists, lifts outer
indices and merges them. Dot reordering separately computes operand reductions,
contracting maps and a flop-based threshold; its cost arithmetic remains finite.

ReorderReduceDotToDotReduce returns optional<Status>. The caller tests optional
engagement and returns OkStatus without propagating the contained Status. This
is preserved as source control flow, rather than rewritten in the extraction
as “helper succeeded.” No failure injection or claim that a valid graph reaches
an error is made; status/error-path correspondence remains an obligation.

## ReduceWindow source details

Empty and rank-zero cases share a local replace_with_span lambda. Its body is
not lexically inside each caller condition. The schemas therefore retain both
the invocation anchor and captured tuple mode. Trivial one-component variadic
rewrites construct a cloned embedded reducer before replacing the graph result;
CloneWithReplacements is classified as construction, not another graph rewrite.

Cumsum-like folding traverses formatting and conversion chains to a uniform
literal, reproduces conversions in order, selects S64 count Iota only for an S64
literal (otherwise S32), then multiplies by Iota+1. Count overflow, literal casts
and repeated floating addition versus multiplication require separate models.

Singleton-window cases retain the exact size/stride/dilation/reversal guard and
the concrete Add/Minimum/Maximum reducer. Cropping is rejected for dynamic inputs;
a crop covering an entire input axis broadcasts the init. Otherwise the new
binary operation is cropped first and positive padding applied afterward.

Full-axis window-to-reduce conversion checks stride/dilation/padding geometry
and result extents. The local predicate does not independently exclude window
reversal, so permitted element order remains a semantic question rather than an
extra premise silently added by a proof generator.

Pad folding distinguishes direct and Convert(Pad) operands, a special conversion
cost gate, interior/base-dilation exclusions, negative-pad exclusion and exact or
converted literal equality with the init. Effective-broadcast detection checks
static shapes and window coverage with an overflow-safe last-window calculation.
It can use the combined window after dropping Pad or retain the existing operand
under the old window. Remaining cases compose edge padding and base dilation
into a new ReduceWindow. Finite arithmetic and backend/layout contracts stay open.

## Checks and next work

All 26 tool/evidence tests and the integrated checkpoint pass. New controls reject
misclassified reducer construction, detached lambda caller guards, missing
declaration evidence and hiding a real call as a declaration. Prior source,
assignment, Lean, refutation and archived native controls remain checked.

No new Lean proof or native pass run is claimed by this extraction update.
Lean size remains S148/H66/R172/A9/C106, total501; accepted full-source rewrites
remain zero. Finish dot/convolution/shared utility extraction, close profile and
path reconciliation, then run the diverse reviewed pilot and complete campaign.
Current aggregate status is in README.md; the whole-file verdict remains open.
