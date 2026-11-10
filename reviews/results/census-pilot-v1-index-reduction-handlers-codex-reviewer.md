# Supplemental independent v1 review: final index and reduction handlers

Reviewer: the same human-authorized separate Codex task `census_pilot_review`;
model/config identifiers remain unknown. Date: 10 November 2026. All three prior
review reports are preserved unchanged. This supplement accepts no source proof
and does not freeze N/F.

**Main finding:** a surviving local operand reassignment in DynamicSlice exposes
a source behavior omitted from its provisional nested-slice schema: a failed
scaled-Iota probe can cause the later nested-slice transformation to drop a
Multiply scalar. A small exact-integer candidate computes28 before and4 after.
This report supplies source-path evidence and a replay recipe; it claims no new
native XLA run or Lean refutation. All five requested function bodies were read,
but source/helper semantics remain unclosed.

## Authenticated frozen basis and exact extent

Same v1 archive SHA256
`f119335b261a0930a5a2497f5ba3339570d34c5ee6e4baf4a26345cf12b55ce3`;
manifest SHA256
`da6899931075f018df5d7189c10e8bb87ee4e2560433b2d96e3c1d85f1bdaca4`.
XLA `e58e523b11f1fde802a493a776d158007486e1bf`; pass SHA256
`1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f`.
All source hashes were rechecked in `/tmp/census-review-8uw99atq`. No live later
packet, new proof or native result was used as v1 review evidence.

| Full body read | Frozen target lines | Provisional schemas inspected |
| --- | ---: | ---: |
| HandleSlice | 7655–8117 | 18 |
| HandleDynamicSlice | 8142–8433 | 13 |
| HandleDynamicUpdateSlice | 8435–8732 | 9 |
| HandleReduce | 9044–9550 | 23 |
| HandleReduceWindow | 9570–10113 | 31 |
| Total | 2104 source lines | 94 schemas |

I traced all 29 selected direct local call edges, with 21 distinct helper names:
ConstructToDotMaps, DotHasOnlyBatchAndContractingOnOneOperand,
RemoveRedundantStride, ReplaceInstructionIfCompatible, SameShape,
TrySimplifyScalarSlice, TryToReorderSliceAndReshape, TryToReorderSliceAndReverse,
IsAll, BroadcastReduce, IsScalarConstantInf, IsScalarConstantNegInf,
IsScalarConstantZero, MatchArgMax, MatchArgMin, MergeReduces,
ReductionComputationsEquivalent, ReorderReduceDotToDotReduce,
ReplaceReduceWithReshape, ShouldBroadcastReduce, HasNegativePadding. Their bodies
were read in this or the prior same-frozen reviews; transitive local source
reading additionally covered ConstructFromDotMaps and MatchArgMinMax. External
creation/query/window/cost APIs and backend contracts remain open.

The earlier independently rebuilt 2299-line/71-law v1 pilot is still the proof
validation basis. This supplement ran no new XLA/Lean probe. Independent Python
integer/list arithmetic checked the scaled nested-slice witness28 versus4.

## P1: failed scaled-Iota probe changes the later nested-slice meaning

The important local dataflow is explicit:

1. HandleDynamicSlice initially binds operand to its actual data input.
2. The Iota-specialization block admits rank-one input/result, output extent1
   and output element S32/U32. Its helper recognizes Multiply only when operand1
   is a Broadcast of a scalar; the scalar need NOT be constant.
3. At8328 it captures multiplier; at8329–8330 it replaces the LOCAL operand
   pointer by the Multiply's operand0. This is not an IR mutation yet.
4. At8333 it checks whether that stripped node is Iota. A failed check does not
   restore operand. No graph rewrite or return occurs there.
5. The nested test at8385 uses that surviving local pointer. It can therefore
   recognize an inner DynamicSlice beneath the Multiply even though the actual
   outer data operand is still Multiply(innerDS, Broadcast(multiplier)).
6. After type/range guards at8388–8398, the real IR write at8401–8402 replaces
   the outer data operand with the inner slice's base. The per-index loop uses
   the inner slice's extents and starts and does not reinsert the multiplier.
   MarkAsChanged occurs after the loop, at8430.

The source behavior is consequently wider than the provisional
`HandleDynamicSlice/nested` LHS
`DynamicSlice(DynamicSlice(x,inner),outer)`. Its generic “current matcher bindings
apply” caveat does not identify or model this additional captured graph shape.
This is a semantic-partition omission despite complete lexical-site mapping.

### Exact small candidate and source route

Use s32 values, base x=[1,2,3,4,5,6,7,8,9,10], inner width6/start1, outer width1/
start2 and scalar7. The actual original graph returns
`7*x[clamp(1,0,4)+clamp(2,0,5)] = 28`; the constructed nested replacement returns
`x[3] = 4`. No overflow, NaN, floating permission or reduction-domain issue is
involved. Both differences10-6=4 and10-1=9 fit s32, satisfying the nested guards.

Suggested native HLO recipe, not parsed or verifier-tested by this reviewer:

```hlo
HloModule scaled_nested_dynamic_slice
ENTRY main {
  x = s32[10] parameter(0)
  inner_start = s32[] parameter(1)
  outer_start = s32[] parameter(2)
  scalar = s32[] parameter(3)
  inner = s32[6] dynamic-slice(x, inner_start), dynamic_slice_sizes={6}
  factor = s32[6] broadcast(scalar), dimensions={}
  scaled = s32[6] multiply(inner, factor)
  ROOT result = s32[1] dynamic-slice(scaled, outer_start), dynamic_slice_sizes={1}
}
```

Runtime start parameters avoid the earlier constant-index-to-static-Slice path
at8270–8300. Alternatively explicitly disable that conversion and record the
option. The inner output width6 avoids the Iota output-width1 block. The outer
actual input width6 differs from result1, so scalar/full-shape/full-axis-zero
exits do not apply. A runtime scalar prevents constant-one/zero multiplier
recognition from preempting the intended route. The prospective rewritten
outer Slice's base shape10, result shape1 and start3 remain shape-compatible;
this candidate concerns values rather than an intentionally invalid input.

Proposed census correction: retain a direct-nested child of the old schema and
add an explicit failed-scaled-probe child, e.g.
`HandleDynamicSlice/nested-after-scaled-probe`, with actual original input
Multiply(DynamicSlice(...), Broadcast(scalar)), output rank/extent/type gate,
failed Iota test, range guards and the dropped scalar in the replacement.
Preserve a stable parent/lineage rather than equating schema count with N.
The actual source guard must not be silently strengthened to demand a direct
DynamicSlice data operand. The existing arbitrary-rank logical nested theorem
can remain correct for its direct logical profile while being insufficient for
this newly identified source path.

Next validation: legal-HLO before/after verifier checks; no-pass, initialized
handler and full one-pass evaluator runs; exact original/replacement node and
parameter capture; strict s32 words and signed observations. Controls should
include direct nesting without Multiply, runtime scalar1, true scaled-Iota,
Multiply in the opposite operand orientation (not matched by this helper),
output width2, and enabled/disabled constant-index conversion where relevant.
Then add a kernel-checked pointwise counterexample/general scale-omission law and
independently review source/certificate correspondence. No source defect verdict
or accepted refutation is asserted by this source-only report.

## Secondary conditional source/definedness obligations

### Unit-reshape DynamicSlice can erase an empty inserted axis

The unit-reshape movement at8221–8250 fills all source slice sizes with1 and only
copies sizes for non-unit unmodified source axes. An inserted unit output axis
may legally be sliced with size0; that zero need not survive the movement.
Candidate: x s32[2], reshape to s32[1,2], outer DynamicSlice result s32[0,1].
The new DynamicSlice of x can have shape[1], then the final Reshape requests
[0,1], changing count1 to0. Use zero starts to avoid prior full-axis index
simplification where applicable. Unlike Reshape's empty-output branch, this
input reshape is nonempty; ordinary-pass reachability still needs verification
of preceding Broadcast/reshape/helper rewrites and every exact option.

This is a separate count-preservation obligation from the earlier Reshape-over-
DUS empty-update concern. Record zero slice sizes on inserted/deleted unit axes;
do not adopt the source comment as a proof that all such sizes are one. No
native or kernel refutation is claimed here.

### Slice/Reshape decomposition requires nonzero loop divisors

TryToReorderSliceAndReshape guards the aggregate operand_sub_dim_elements at
7511–7514, but its reverse loop at7519–7542 divides/mods by EACH operand dim_size.
That aggregate guard alone does not establish all those dimensions nonzero.
Source-inspected direct-helper candidate: x shape[0,2], reshape to[2,0], then
unstrided Slice {[0:1],[0:0]} with result[1,0]. Only output dimension0 is sliced.
The checked tail product is2; slice_elements initially0. Processing input dim1
(size2) sets slice_elements to1; the next dim0 has size0 and the `>=` branch
reaches modulo/division by0 at7525–7529.

This is a conditional helper/undefinedness concern, not a confirmed full-pass
crash. Ordinary traversal of an initial empty Reshape can replace it with an
empty Constant first, blocking this route. Generated nodes and other caller/
visit contexts require separate reachability proof. A sanitizer/direct-helper
replay, legal-input witness and normal-pass suppression control would be needed
before promoting the candidate. Do not equate a missing local guard with a
reachable whole-pass bug.

### DUS-to-Pad accesses the first index before scalar/full-overwrite cleanup

The option-controlled Broadcast-base path reads operand(2) at8454 before its
rank loop and before SameShape forwarding at8545. A rank-zero DUS taking an
empty scalar-index span has only base/update operands. Its normal handler has
an async exclusion but no local rank-zero guard before this read. A direct-
handler Broadcast-scalar base candidate therefore needs an index-existence
partition. Ordinary full-pass Broadcast canonicalization may remove that base
first; the option and exact visitation route must be checked. Keep this separate
from the prior Reshape handler's analogous index read at7164.

## Per-handler semantic and outcome reconciliation

### Slice

- Existing-input compatibility comes first. Pad handling distinguishes any-axis
  padding-only, exact undo and interior-free unit-stride inside regions. It can
  overwrite a constructed node's shape with the original Slice shape. Failed
  undo compatibility can continue into inside-Pad extraction.
- Slice-of-DUS requires one scalar index per rank axis, all ConstantScalar and
  GetFirstInteger success; it clamps starts mathematically in int64, distinguishes
  exact unstrided update forwarding from inside-update slicing and applies a
  layout equality condition only to the latter.
- Nested static slices require BOTH unstrided; starts/limits are added. Broadcast
  shortcuts distinguish slicing only replicated axes from a later general
  mapped-axis slice. Effective-scalar Concat selection is delegated in between;
  its compatibility failure takes a new-Slice fallback, not a skipped rewrite.
- Slice-through-Dot constructs candidate slices/Dot before deciding whether both
  operands still have free dimensions. A failed final heuristic may leave unused
  allocated nodes and continue. Its helper is called with TrueNumDimensions,
  which must not be casually equated with actual ranks in a semantic guard.
- Concat extraction records prefix starts/limits, exact single-piece forwarding
  versus strict sub-concat slicing, plus layout/derived metadata on a new Concat.
- Slice/ReduceWindow conversion requires option, unstrided, one use and specific
  padding/window geometry; preserve the actual initializer/reducer and reduction
  domain, not just an abstract sum. Later helpers run in order: reshape reorder
  only if layout-insensitive, reverse reorder, then redundant-stride removal.
  The two previously certified empty-slice shape failures remain separately
  scoped; this review does not replace their earlier native/Lean evidence.

Remaining: source-attribute/index maps, zero extents, initializer/reassociation,
layout/frame/alias/effect contracts, arithmetic/divisor ranges, statuses and all
allocations that precede a rejected heuristic or replacement.

### DynamicSlice

Async exclusion precedes scalar/full-shape forwarding and full-axis index-zero
cloning. The full-axis path copies mutable_operands by value then clones; those
local vector edits must not be mistaken for immediate IR writes. Broadcast,
unit-reshape and Transpose movement follow, with only the latter two needing
layout-insensitive mode. Constant-index conversion is option/nonconstant-data/
memory-space constrained, rejects missing/negative GetFirstInteger values and
can return from the handler without considering later rules.

The Iota block's accepted multiplier is operand1's scalar Broadcast, not an
AnyOrder or necessarily-constant factor. Clamp in index type, optional result-
type conversion, source Iota wrap and multiplier arithmetic remain obligations.
The surviving failed-Iota local binding is the main finding above. Nested DS
checks every axis range BEFORE the first real data-operand write, then writes
data and each newly clamped/cast/summed start sequentially, marking changed only
after the loop. Prefix mutations/status failures require a frame contract.

Remaining: the new binding partition and native/Lean confirmation, async source
context, index representation and high-bit oracle profile, zero/unit size maps,
finite clamps/casts/add, dynamic layouts and all API/effect states.

### DynamicUpdateSlice

Async exclusion comes first. Option-controlled Broadcast-to-Pad recognizes host
offload annotations through formatting nodes, collects constant starts, clamps
and returns on success. It precedes full-overwrite forwarding. Pad-overwrite-to-
Concat requires exactly one padded axis, no negative/interior padding, constants,
positive unpadded extent, exact overwrite placement and matching layout when
sensitive. Full-axis zero-index cloning precedes empty-update elimination;
therefore “empty updates always disappear immediately” is not an accurate
ordered path description. A one-pass earlier clone can postpone that cleanup.

Nested DUS recognizes the inner data DynamicSlice from the same base with the
same OUTER start pointers. It range-checks first, replaces update operand1 with
the deeper update, then constructs clamps/cast/add and replaces each index,
marking changed after all writes. Preserve conditional slot indices, legacy
versus scalar-index shape invariants and retained shared users.

Remaining: legal index-form/rank-zero partitions; host-offload and dynamic shape
contracts; clamping and finite sum/cast proof; zero-update cleanup reachability;
all sequential mutation, alias, control, sharding/layout and error observations.

### Reduce

Empty representative input/output delegates to initializer broadcasts, then
singleton tuple unwrapping clones/adds an embedded computation BEFORE replacement.
Same-element-count elimination relies on the documented reducer identity law;
layout-sensitive operation otherwise exits early. Nonidentity but shape-verifier-
accepted reducers are not valid refutations of that documented operator domain.

After layout exclusion, negate-sum mutates the Reduce input, snapshots users,
creates Negate and rewires the selected old users. ArgMin/Max constant cases use
explicit role matchers and zero index preference. ReorderReduceDotToDotReduce
then returns optional<Status>, whose ENGAGEMENT is tested by the caller at9140;
contained errors are discarded when the caller returns OK at9141. That behavior
and candidate allocations before a failed cost threshold are ALREADY explicitly
recorded in the frozen schema; they are not new review discoveries.

Tuple output exits after that delegation. Single-output paths then include
transpose movement (optional result transpose), merge, two reshape cases in
priority order, concat reduction/map chaining, batch-to-contract Dot changes,
reuse of matching ArgMin/Max, scalar Broadcast idempotent reducers, mapped base-
axis reduction and replicated-axis Add-to-count multiplication. Each requires
actual initializer identity and appropriate reassociation/numeric permissions.
The replicated-axis rule TF_RET_CHECKs sorted Broadcast dimensions; this is a
local source precondition, not proof every HLO Broadcast is globally ordered.

ReductionComputationsEquivalent accepts identical computation objects or two-
parameter Add/Multiply/And/Or role-correct roots; it is not an arbitrary function
equality oracle. MergeReduces sorts local copies of dimension vectors, not the
original instruction attributes. ArgMin/Max matchers use specific four-parameter
roles, init infinities/zero and Iota, unlike the looser Scatter matcher found in
the first supplement.

Remaining: coupled tuple domain, exact reducer/identity and allowed reassociation,
minmax/NaN/tie/index contracts, Dot/reshape/concat geometry and typing, finite
count/flop/cost arithmetic, module/metadata/API frames and discarded status paths.

### ReduceWindow

Empty input/output broadcasts initializers first; scalar input returns inputs
(with tuple-root condition for variadic output). Locals named map_computation_root
and replacements in that scalar branch do not construct a Map; actual code
pushes inputs into the replacement span. Singleton variadic conversion clones
an embedded reducer; all other tuple cases then return.

Single-output cumulative-sum detection unwraps Reshape, SAME-ELEMENT-TYPE Bitcast,
Convert, Slice, Copy, then scalar Broadcast; it replays collected conversions in
reverse order on the scalar literal. An entered uniform/add/zero-init candidate
whose scalar is not Constant returns from the handler, suppressing later window
rules. The reduction axis requires full cumsum geometry; unit window axes check
only their stated pad/base-dilation conditions. Count type is S64 only for an
S64 final literal, otherwise S32. General count range, overflow/conversion and
floating repeated-add versus count-multiply observations remain unproved.

Next singleton Add/Min/Max windows normalize positive padding and negative crop.
Dynamic operands with negative padding return unchanged. Full-axis crop returns
initializer Broadcast; other cases construct elementwise op, optional Slice
BEFORE Pad, then replace. The optional full-dimension window-to-Reduce path follows.

Only then does Pad or Convert(Pad) folding run. Convert/one-nontrivial-axis uses
padding-ratio policy and can return early. Interior padding plus base dilation
is rejected, negative Pad is rejected, and pad value/init equivalence is tested
unconditionally in the actual code, despite the comment emphasizing preexisting
window padding. It accepts pointer equality or constant literal equality after
optional ConvertToShape. New window arithmetic combines base dilation/edge/interior
padding. Effective-Broadcast tests cover the single unpadded element in EVERY
window and use overflow-checked last-window start. Depending on combined versus
existing-window success, the source retains the original operand or uses the
unpadded operand; Convert recreation occurs only on the corresponding path.
CreateBroadcastSequence invokes an UpdateLayout/AddInstruction callback. Otherwise
a new ReduceWindow is constructed with the combined window.

Remaining: complete window/padding/runtime-dimension/index semantics; initializer
identity and coupled/tuple contracts; count/convert/range and floating numerical
permissions; cost/ratio/domain preconditions; callback, metadata, graph/control,
allocation and failure outcomes. A scalar/nonidentity probe alone cannot answer
these domain-sensitive obligations.

## Cumulative completion of body reading, not semantic review

All58 Handle-prefixed bodies have now been read across the four independent
reports: 57 visitor overrides and one shared helper. Every selected direct local
helper for the final batch was inspected, but this is NOT closure of all 161
source function definitions, all external/virtual contracts or all 487 provisional
schemas. Exact caller/path composition, the newly found binding split and every
source-to-theorem/observation acceptance gate remain open. N/F cannot be frozen
from this reading milestone.

No new lexical replacement site was shown missing; the scaled-probe finding
shows why that fact is weaker than semantic census completeness. Prior reports,
including the Broadcast-ordering correction in the third report, retain their
separate validation and scope. The 94 frozen source-case IDs in this batch remain
unaccepted and are enumerated below.

### Open source-case IDs from shape-cases.json

- `HandleSlice/identity`
- `HandleSlice/padding-only`
- `HandleSlice/undo-pad`
- `HandleSlice/inside-pad`
- `HandleSlice/exact-dynamic-update`
- `HandleSlice/inside-dynamic-update`
- `HandleSlice/compose-unstrided`
- `HandleSlice/broadcast-only-dims`
- `HandleSlice/broadcast-sink`
- `HandleSlice/dot-operands`
- `HandleSlice/concat-exact-piece`
- `HandleSlice/concat-subrange-single`
- `HandleSlice/concat-subrange-multi`
- `HandleSlice/reduce-window`
- `HandleSlice/scalar-slice-delegation`
- `HandleSlice/reshape-reorder-delegation`
- `HandleSlice/reverse-reorder-delegation`
- `HandleSlice/stride-delegation`

### Open source-case IDs from tensor-index-cases.json

- `HandleDynamicSlice/scalar`
- `HandleDynamicSlice/same-shape`
- `HandleDynamicSlice/zero-full-axis-indices`
- `HandleDynamicSlice/broadcast-scalar`
- `HandleDynamicSlice/broadcast-array`
- `HandleDynamicSlice/unit-reshape`
- `HandleDynamicSlice/transpose`
- `HandleDynamicSlice/constant-indices`
- `HandleDynamicSlice/iota-plain-same-type`
- `HandleDynamicSlice/iota-plain-convert`
- `HandleDynamicSlice/iota-scaled-same-type`
- `HandleDynamicSlice/iota-scaled-convert`
- `HandleDynamicSlice/nested`
- `HandleDynamicUpdateSlice/pad-scalar-list`
- `HandleDynamicUpdateSlice/pad-tuple`
- `HandleDynamicUpdateSlice/pad-concatenate`
- `HandleDynamicUpdateSlice/full-update`
- `HandleDynamicUpdateSlice/pad-concat-high`
- `HandleDynamicUpdateSlice/pad-concat-low`
- `HandleDynamicUpdateSlice/zero-full-axis-indices`
- `HandleDynamicUpdateSlice/empty-update`
- `HandleDynamicUpdateSlice/nested`

### Open source-case IDs from reduction-cases.json

- `HandleReduce/empty-delegation`
- `HandleReduce/singleton-tuple`
- `HandleReduce/same-element-count`
- `HandleReduce/negate-sum`
- `HandleReduce/argmin-constant`
- `HandleReduce/argmax-constant`
- `HandleReduce/dot-reorder-delegation`
- `HandleReduce/transpose-sorted`
- `HandleReduce/transpose-permute-result`
- `HandleReduce/merge-delegation`
- `HandleReduce/reshape-reduced-axes`
- `HandleReduce/reshape-output-axes`
- `HandleReduce/concat`
- `HandleReduce/dot-batch-all-batch`
- `HandleReduce/dot-batch-residual-reduce`
- `HandleReduce/reuse-argmax`
- `HandleReduce/reuse-argmin`
- `HandleReduce/scalar-broadcast-maximum`
- `HandleReduce/scalar-broadcast-minimum`
- `HandleReduce/scalar-broadcast-and`
- `HandleReduce/scalar-broadcast-or`
- `HandleReduce/broadcast-base-axes`
- `HandleReduce/broadcast-replicated-axes`
- `HandleReduceWindow/empty-tuple`
- `HandleReduceWindow/empty-single`
- `HandleReduceWindow/scalar-tuple`
- `HandleReduceWindow/scalar-single`
- `HandleReduceWindow/singleton-tuple`
- `HandleReduceWindow/cumsum-i64-canonicalize-literal`
- `HandleReduceWindow/cumsum-i64-reuse-literal`
- `HandleReduceWindow/cumsum-i32-canonicalize-literal`
- `HandleReduceWindow/cumsum-i32-reuse-literal`
- `HandleReduceWindow/singleton-crop-all-add`
- `HandleReduceWindow/singleton-add-no-pad-no-crop`
- `HandleReduceWindow/singleton-add-no-pad-crop`
- `HandleReduceWindow/singleton-add-pad-no-crop`
- `HandleReduceWindow/singleton-add-pad-crop`
- `HandleReduceWindow/singleton-crop-all-minimum`
- `HandleReduceWindow/singleton-minimum-no-pad-no-crop`
- `HandleReduceWindow/singleton-minimum-no-pad-crop`
- `HandleReduceWindow/singleton-minimum-pad-no-crop`
- `HandleReduceWindow/singleton-minimum-pad-crop`
- `HandleReduceWindow/singleton-crop-all-maximum`
- `HandleReduceWindow/singleton-maximum-no-pad-no-crop`
- `HandleReduceWindow/singleton-maximum-no-pad-crop`
- `HandleReduceWindow/singleton-maximum-pad-no-crop`
- `HandleReduceWindow/singleton-maximum-pad-crop`
- `HandleReduceWindow/full-dimensions`
- `HandleReduceWindow/pad-broadcast-direct-combined`
- `HandleReduceWindow/pad-broadcast-direct-existing`
- `HandleReduceWindow/pad-fold-direct`
- `HandleReduceWindow/pad-broadcast-convert-combined`
- `HandleReduceWindow/pad-broadcast-convert-existing`
- `HandleReduceWindow/pad-fold-convert`

