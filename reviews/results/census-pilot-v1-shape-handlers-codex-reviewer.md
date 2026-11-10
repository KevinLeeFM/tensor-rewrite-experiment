# Supplemental independent v1 review: Broadcast, Compare, Pad, Reshape, Transpose

Reviewer: the same human-authorized separate Codex task `census_pilot_review`;
model/config identifiers remain unknown. Date: 10 November 2026. This is a
bounded source/contract inspection, not final human sign-off or a checked C++
translation. Both prior review reports are preserved unchanged.

**Result:** the frozen source supports a partial-order NaN concern in Compare,
exposes conditional empty-update/rank-zero obligations in Reshape-over-DUS, and
requires explicit metadata, user-rewiring and in-place mutation contracts across
these shape handlers. I also correct an overstatement in my first review about
Broadcast axis ordering. No native XLA or Lean result was newly produced for
these candidates, no source proof is accepted, and N/F remain unfrozen.

## Frozen basis and review extent

All inspection used `/tmp/census-review-8uw99atq`, extracted from v1 archive
SHA256 `f119335b261a0930a5a2497f5ba3339570d34c5ee6e4baf4a26345cf12b55ce3`;
manifest SHA256
`da6899931075f018df5d7189c10e8bb87ee4e2560433b2d96e3c1d85f1bdaca4`.
XLA commit `e58e523b11f1fde802a493a776d158007486e1bf`; target SHA256
`1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f`.
All frozen source hashes were rechecked and remain unchanged. Live follow-up
packets, new proofs and parent-reported native observations are not used as
frozen v1 evidence.

| Full body read | Frozen target lines | Provisional schemas compared |
| --- | ---: | ---: |
| HandleBroadcast | 5770–5905 | 13 |
| HandleCompare | 5907–6051 | 23 |
| HandlePad | 6198–6403 | 5 |
| HandleReshape | 6911–7198 | 11 |
| HandleTranspose | 10407–10747 | 11 |
| Total | 1116 source lines | 63 schemas |

The frozen typed inventory has 41 selected direct local call edges here, naming
19 distinct helpers. I read their bodies: TryToSinkBroadcastAfterElementwiseOps,
OutputIsPermutationOfOperandElements, OutputIsSubsetOfOperandElements, IsAll,
IsNonNegative, SameShape, ReplaceInstructionIfCompatible,
TryRemovingBitcastOrReshapeTransposeChain, TryHoistTransposeOfReshape,
ReshapeLeavesDimensionsUnmodified, BitcastingOperandOfReshapeOrCopyChain,
ReplaceWithBitcast, TryFoldTransposeIntoScatter, IsParameterLike,
IsPermutationOfIota, SwapOperandsInDotPrecisionConfig,
OnlyPermutesDegenerateDims, TransposeIsBitcast, SimplifyTransposeOfBroadcast.
Relevant transitive local bodies read include IsPositive, IsAnyOperandComplex,
GetConstantValue, HasMatchDimensionTile, FindContiguousChunks and
IsContiguousChunk. External/virtual implementations are not thereby closed.

The first review's independent 2299-line/71-law v1 Lean replay remains the proof
validation basis. This supplement ran no XLA/Lean candidate replay. A small Python
calculation confirmed the ordinary partial-order NaN comparison truth table;
that calculation is not binary32/source correspondence evidence.

## Correction: Broadcast ordering belongs to a specific interface/profile

[SUPERSEDES the first review's Advisory claim that ordering/uniqueness are a
universal HLO Broadcast legality condition.]

I conflated the client BroadcastInDim surface with the more general HLO op.
Frozen `ShapeVerifier::HandleBroadcast` in `service/hlo_verifier.cc:1741–1761`
checks element type, exact dimension count, ranges and corresponding extents.
`InstructionVerifier::HandleBroadcast:4734–4751` checks sortedness only when
verify_broadcast_dimensions_order is enabled; `hlo_verifier.h:156–157` defaults
that option to false. The explicit setter at `:66–69` enables it. The general
HloBroadcastInstruction constructor (`hlo_instructions.cc:2227–2233`) appends
its operand/dimension list without supplying the client's strict-order check.

Client `ShapeInference::InferBroadcastShape` at `:3979–4032`, explicitly
commented as BroadcastInDim, requires strictly increasing dimensions. This is
a distinct interface. `HandleBroadcast:5787–5796` intentionally handles an
unsorted equal-rank/equal-count mapping by an inverse Transpose.

Therefore do NOT add unconditional sortedness to IndexMaps.BroadcastAxes merely
on my earlier advice. It already has exact-length/range and broadcastIndex adds
extent equality, suitable for a more general logical pullback. A source adapter
must identify the actual operation contract, constructor/builder, applicable
verifier profile and mapping invariants. Absence of a duplicate-axis check in a
default verifier alone is NOT proof that every duplicate mapping is valid HLO.
Source permutation construction still needs its bijection premise justified.
The original report is preserved; this paragraph is its correction trail.

## P1 candidate: IsNonNegative does not establish ordered GE/LE in the presence of NaN

Verified exact simplifier locations:

- GE guard:5942–5943; replacement with true:5944.
- LE guard:5945–5946; replacement with true:5947.
- Partial-order LT/GT false-result branches:5936–5941.

(The earlier reviewer chat reference to5950+ was incorrect; those lines start
the integral-self case. The references above were checked directly.)

IsNonNegative at540–607 returns true for floating Abs, Exp and pointer-self
Multiply without a non-NaN condition. Abs of NaN, Exp of NaN and NaN*NaN can
remain NaN under an ordinary IEEE profile. In that profile, NaN>=0 and 0<=NaN
are false, but the GE/LE branches replace the comparison by true. There is no
local fast-math or comparison-order guard on these branches.

The frozen comparison code supports an independently meaningful partial-order
profile: `comparison_util.h:92–100` documents floating defaults as partial,
`:190–220` handles total/weak cases separately then uses the ordinary comparator;
`HloEvaluator::HandleCompare` at `hlo_evaluator.cc:1658–1681` constructs that
Comparison from the actual direction, element type and comparison order. This
is source-inspected candidate correspondence, not a fresh evaluator result.

Suggested finite-rank witness: parameter f32[] NaN, producer Abs/Exp/self-product,
compare producer>=+0 (or +0<=producer), strict partial-order configuration.
Positive finite values and partial-order LT/GT provide controls. LT/GT are NOT
universal safe controls across total/weak ordering: NaN sign/order behavior must
be partitioned separately. Maximum's OR-recognition and recursive Minimum/Power/
Select/Broadcast cases require their actual NaN and numeric contracts too;
Maximum's result must not be assumed to propagate NaN without checking its
particular profile. The helper's constant branch explicitly rejects NaN/-0,
which does not establish such a postcondition for every other constructor.

Proposed source-contract correction: split the four nonnegative schemas by
producer recognition, dtype, comparison mode, NaN reachability and adopted
numerical permission. State the property needed by each caller. “Not a negative
ordered number” is insufficient to infer ordered GE/LE true for NaN. Retain the
actual guard; do not silently add a non-NaN premise to describe source behavior.
Next: native no-pass/handler/pass profiles and a necessary-IEEE comparison
certificate, followed by independent observation/source correspondence review.

## Conditional shape/API obligations: Reshape over DynamicUpdateSlice

At7147–7157, the unit-axis transformation requires a trivial reshape of the
DUS RESULT, one user and absent DUS/base sharding. It does not explicitly check
the update extents on deleted axes. The comment at7148–7149 claims the added/
removed dimensions will be one in both update and result; input legality alone
does not establish this for empty updates.

Source-inspected direct-handler candidate: base/result s32[1,2], update s32[0,1],
outer reshape s32[2]. Deleting result axis0 drops update axis0 as well and builds
new_slice_shape=[1]. The constructed reshape would convert a zero-element
update into a one-element update. `InferDynamicUpdateSliceShape` permits an
update extent0 provided it fits the input (`shape_inference.cc:3731–3743`).

A second direct-handler precondition is rank zero. The DUS constructor taking
an empty start-index span (`hlo_instructions.cc:4273–4282`) appends only base and
update. Rank-zero DUS with scalar base/update and no indices is allowed by the
inspected shape checks (the default allow_scalar_indices is true in
`shape_inference.h:273–276`). Yet the reshape transformation unconditionally
reads dus->mutable_operand(2) at7164 to choose the inserted-zero index type.
Outer reshape scalar→[1] is a candidate exposing that absent operand.

**Reachability caveat:** ordinary full-pass traversal may remove these DUS nodes
before visiting the outer Reshape. Same-shape DUS forwarding occurs at8543–8546;
empty-update forwarding occurs at8667–8671. These are therefore conditional
source-adapter/direct-handler obligations, NOT established ordinary full-pass
counterexamples. An async computation could matter because HandleDynamicUpdateSlice
returns immediately at8438–8440, while this Reshape handler has no analogous
local async guard. Actual legal async-HLO visitation and other early helper
behavior must be verified before claiming full-pass reachability.

Proposed correction: record update-count preservation and index-operand existence
as explicit unresolved dependencies for HandleReshape/dynamic-update-unit-dims.
Add empty/rank-zero and normal-postorder/async/direct-handler partitions rather
than accepting the source comment as a theorem. Next native tests should verify
legal inputs, isolate the actual visitor context, require post-rewrite verifier
results and record whether preceding DUS cleanup suppresses the candidate.

## Ordered path, frame and API reconciliation

### Broadcast

1. Sorted dims plus equal counts returns a new Reshape before all other paths.
   Same rank/equal counts then returns an inverse-permutation Transpose; its
   bijection premise must come from the actual legal input contract.
2. Insert-only reshape removal reverses the inserted-axis list before erasing
   local dims. At5810–5821 it invokes a module original-value recovery callback
   before attempting the default-relay replacement. This is a metadata/module
   effect even if a later replacement skips or fails.
3. Optional sink helper processes ALL qualifying live users, excluding Copy,
   Fusion and non-elementwise ops. Every operand must be scalar Broadcast or
   equal-shape/equal-dims Broadcast. It builds reduced operands/new user/new
   Broadcast and rewires user uses with ReplaceAllUsesWith. Successful prefixes
   may exist if a later status fails. Handler MarkAsChanged occurs only after
   helper returns true, not as a transactional marker for every internal write.
4. The scalar-source fallback iterates users but returns after its FIRST live
   permutation/subset match. It uses MakeStaticShape(user->shape()), allocates
   a Broadcast, marks changed BEFORE ReplaceAllUsesWith, and returns that status.
   If no user qualifies, the scalar branch still returns; Iota/compose/drop-unit
   cases therefore inherit a nonscalar-source condition.
5. Iota and nested-Broadcast rewrites precede the layout-sensitive early exit;
   only drop-degenerate-axes is behind that exit and its own option.

Remaining: pure index/shape laws plus dynamic runtime dimensions (MakeStaticShape),
recognized user/side-effect contracts, recovery callback semantics, all-use/root
rewiring/control/metadata and partial-error outcomes; layout/device policies.
Neither a generic reindex theorem nor scalar value constancy alone closes this.

### Compare

Unsigned-zero folds precede nonnegative-recognition folds, then integral pointer-
self comparisons, PRED constant identities, causal-mask and min/max operand
updates. The unsigned and integral checks use the operand element type, while
comparison order is an independent attribute. The mask fold requires a GE
Compare predicate, IsAll1/0 branches and SameShape of inner and outer PRED outputs.
It does not accept arbitrary scalar predicates in place of that shape guard.

For GT min/max updates, the Minimum matcher is in an else-if after the Maximum
matcher. If Maximum structurally matches but neither pointer equality holds,
Minimum is not attempted. The selected operand is mutated in-place at6029–6045,
then MarkAsChanged; comparison direction/order and other attributes remain.
No graph-context deletion theorem describes that mutation by itself.

Remaining: recognized sign-property semantics, comparison modes, dtype/promotion,
IsAll and mixed/numeric branch contracts, min/max NaN behavior, shape compatibility,
and every replacement versus operand-mutation frame/status outcome.

### Pad

Empty input returns a Broadcast first. Interior padding on input extent1 is
cleared in a new Pad and returns before other simplifications. The subsequent
all_zero flag tracks EDGE low/high only; interior axes are separately collected.
Thus “all_zero” is not independently a no-op premise; successful compatibility
must also establish shape agreement. Failed compatibility continues.

Projection of Pad(Broadcast) occurs BEFORE negative-edge normalization. It
requires padded/interior axes a strict subset, Broadcast one user, source rank
bounded by selected count and every mapped Broadcast axis in that set. It
mutates the EXISTING Broadcast shape/dimensions, clears its sharding, updates
layout, constructs a smaller Pad/config and an outer Broadcast at6316–6325.
Negative padding reaches the later branch only if this path did not return.
Final replacement failure cannot be modeled as restoring the previous Broadcast.

Negative-edge normalization constructs an intermediate nonnegative Pad, overrides
its result element type to the original Pad's type, copies layout and constructs
a Slice. Negative-low negation, negative-high addition and shape arithmetic must
be range-checked. Final shape equality is checked at6393–6397, ignoring tiles
only in layout-insensitive mode; shape/config/layout writes and intermediate
allocations already occurred before that check or later API status.

Remaining: complete Pad/crop/interior index semantics; zero/dynamic/type profiles;
selected-axis projection invariants; finite arithmetic; sharding/layout and
backend callbacks; input/index use graph, aliases and partial-state/status paths.

### Reshape

Ordered exits: empty constant (default literal layout if absent, explicit relay
true); SameShape identity (frontend-attribute preservation false); composition
(explicit relay true); one-use Rng shape mutation; shared chain removal; optional
layout-insensitive transpose hoist; layout-sensitive copy reorder; Broadcast,
Iota, unit-axis DUS; finally a possible chain-to-Bitcast replacement.

Copy reorder is asymmetric with HandleCopy: a before-Copy is required. Old
hardware=false permits rewrite when new hardware=true or a before-Copy exists
(which it does in this matched branch); old/new hardware both true additionally
needs an after-Copy. Source host-memory input vetoes the rewrite. Allocation
estimates and the 10*before/9 threshold are signed finite arithmetic. New copy
omission uses equality ignoring memory space; the new inner operation is
Bitcast or Reshape according to the hardware predicate.

Iota mixed-radix generation needs CommonFactors iterator/boundary invariants,
actual loop bounds at7121 (not just the existence of next_dim), word/floating
arithmetic and host multiplier bounds. RNG shape changes need distribution/
state observations, not fixed-sample equality. The DUS assumptions are detailed
above. Shared chain removal may choose existing-node replacement or new Bitcast
with their distinct relay/status behavior.

Remaining: all source helper adapters and physical/dynamic/backend contracts,
RNG and metadata/effect policies, copy profitability arithmetic, Iota finite
semantics, DUS count/index validity and prior-handler reachability, API frames.

### Transpose

1. First attempts Scatter folding; it can suppress even an identity-transpose
   branch. Requires option, one-use single-output simplified Scatter, no explicit
   batching and nondecreasing write-run length. It creates transposed base and
   update (index axis0 retained) and remaps scatter dimensions through inverse p,
   preserving reducer and sorted/unique flags before default-relay replacement.
2. Sorted-permutation identity records module recovery metadata BEFORE forwarding.
   Composition then returns a new transpose; shared chain removal follows.
3. Canonical versus general Dot exchange is selected by supports_non_canonical_dots.
   Both enforce one use and the parameter-like policy. IsParameterLike follows
   ANY chain of one-operand instructions, not merely declared pure operators.
   Canonical mode checks common batch list as a permutation of iota, contracting
   axes and exactly one free axis. General mode checks the batch-prefix and
   swapped free blocks, creates a Dot via .value(), overwrites layout, propagates
   derived metadata and CHECK_OKs replacement. Precision helper CHECKs exactly
   two operand-precision entries, then swaps them; legal config correspondence
   must establish that precondition.
4. Degenerate-axis reshape, one-use RNG shape mutation and layout-sensitive
   Bitcast precede the optional space/depth user mutation.
5. Space/depth requires one-use outer Reshape, a single split, small chunk count,
   exact permutation/outer-shape arithmetic. It creates slices/concat then
   mutates OUTER reshape operand at10732–10733; the visited Transpose may remain.
   Prefix allocations and status errors must be recorded. Although its schema
   lists 0<=num_chunks<=5, the split-search first-difference plus product equation
   excludes num_chunks=0: input extent0 would equal the leading split extent0,
   so it could not establish that split. Prove positivity before using division;
   do not report a zero-divisor bug from the upper-bound check alone.
6. Only after these paths does SimplifyTransposeOfBroadcast run. It requires
   sorted original and remapped dims, and in layout-sensitive mode compares the
   extracted relative order. Its default-relay/existing-node API choice differs
   from direct composition and Scatter/Dot constructions.

Remaining: Scatter simplified/write-run contracts (headers alone are not proofs),
full Dot dtype/precision/index correspondence, API/meta/status paths, RNG/physical
storage and backend policy, shape-loop/bounds/product arithmetic, user mutation
and broadcast composition, all implicit aliases and control effects.

## Cumulative status and exact residual scope

Full-body reading is now 53/58 Handle-prefixed definitions: 52 actual visitor
overrides plus the shared AllReduce/ReduceScatter helper. This is reading depth,
not semantic acceptance. The five still only partially read/screened large
bodies are HandleSlice, HandleDynamicSlice, HandleDynamicUpdateSlice, HandleReduce
and HandleReduceWindow. Their full helper closures and all broader external,
backend, observation and source/API contracts remain open.

No additional lexical replacement site omission was established in this batch.
The useful corrections are semantic/profile/outcome dependencies within existing
schemas; 63 cases below remain unclosed. Keep the Broadcast advisory correction,
partial-order versus other compare modes and ordinary-pass versus async/direct-
handler reachability distinctions in any integration or next packet.

### Open source-case IDs from arithmetic-cases.json

- `HandleCompare/unsigned-lt-zero`
- `HandleCompare/unsigned-ge-zero`
- `HandleCompare/unsigned-zero-gt`
- `HandleCompare/unsigned-zero-le`
- `HandleCompare/nonnegative-lt`
- `HandleCompare/nonnegative-gt`
- `HandleCompare/nonnegative-ge`
- `HandleCompare/nonnegative-le`
- `HandleCompare/integral-self-gt`
- `HandleCompare/integral-self-lt`
- `HandleCompare/integral-self-ne`
- `HandleCompare/integral-self-eq`
- `HandleCompare/integral-self-ge`
- `HandleCompare/integral-self-le`
- `HandleCompare/predicate-ne-rhs`
- `HandleCompare/predicate-ne-lhs`
- `HandleCompare/predicate-eq-rhs`
- `HandleCompare/predicate-eq-lhs`
- `HandleCompare/causal-mask`
- `HandleCompare/maximum-first`
- `HandleCompare/maximum-second`
- `HandleCompare/minimum-first`
- `HandleCompare/minimum-second`

### Open source-case IDs from tensor-index-cases.json

- `HandleBroadcast/reshape`
- `HandleBroadcast/transpose`
- `HandleBroadcast/inserted-unit-axes`
- `HandleBroadcast/sink-users-delegation`
- `HandleBroadcast/scalar-user-reshape`
- `HandleBroadcast/scalar-user-reverse`
- `HandleBroadcast/scalar-user-transpose`
- `HandleBroadcast/scalar-user-sort`
- `HandleBroadcast/scalar-user-slice`
- `HandleBroadcast/scalar-user-dynamicslice`
- `HandleBroadcast/iota`
- `HandleBroadcast/compose`
- `HandleBroadcast/drop-unit-axes`
- `HandlePad/empty-input`
- `HandlePad/unit-interior`
- `HandlePad/compatible`
- `HandlePad/broadcast-projection`
- `HandlePad/negative-edges`

### Open source-case IDs from shape-cases.json

- `HandleReshape/empty`
- `HandleReshape/identity`
- `HandleReshape/compose`
- `HandleReshape/rng-shape`
- `HandleTranspose/identity`
- `HandleTranspose/compose`
- `HandleReshape/copy-reorder`
- `HandleReshape/broadcast`
- `HandleReshape/iota-mixed-radix`
- `HandleReshape/dynamic-update-unit-dims`
- `HandleReshape/bitcast-chain`
- `HandleReshape/transpose-chain-delegation`
- `HandleReshape/transpose-hoist-delegation`
- `HandleTranspose/dot-canonical`
- `HandleTranspose/dot-general`
- `HandleTranspose/degenerate-reshape`
- `HandleTranspose/rng-shape`
- `HandleTranspose/layout-bitcast`
- `HandleTranspose/space-depth-user-mutation`
- `HandleTranspose/scatter-fold-delegation`
- `HandleTranspose/chain-delegation`
- `HandleTranspose/broadcast-delegation`

