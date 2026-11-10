# Supplemental independent v1 review: five large handler paths

Reviewer: the same human-authorized separate Codex reviewer task
`census_pilot_review`; model/configuration identifiers remain unknown. Date:
10 November 2026. This supplements the original review without changing it.
No source acceptance or census denominator is changed.

**Result:** full source-body and direct-local-helper reading of HandleAdd,
HandleCopy, HandleConcatenate, HandleDivide and HandleGather identifies two
concrete arithmetic/reducer-role counterexample candidates and a distinct
allocation-before-skip/API-outcome gap. These are source-inspected hypotheses
and mathematical witness calculations, **not fresh XLA or Lean refutations**.
The existing 60 provisional schemas cover the lexical replacement sites in this
batch but do not yet close these semantic/outcome partitions.

## Frozen basis and exact extent

Same authenticated v1 archive as the first report:
`f119335b261a0930a5a2497f5ba3339570d34c5ee6e4baf4a26345cf12b55ce3`,
manifest
`da6899931075f018df5d7189c10e8bb87ee4e2560433b2d96e3c1d85f1bdaca4`.
XLA `e58e523b11f1fde802a493a776d158007486e1bf`; target SHA256
`1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f`.
I used `/tmp/census-review-8uw99atq`, rechecked all frozen source hashes, and did
not inspect the live v3/contraction development. The original review SHA256
remains
`ab1291167a03eafe567d1abf9fb9336b392335bf1c8c53aa729488d56f044fb5`.

| Full body read | Source lines | Provisional schemas compared |
| --- | ---: | ---: |
| HandleAdd | 926–1262 | 19 |
| HandleCopy | 1956–2101 | 10 |
| HandleConcatenate | 2103–2283 | 9 |
| HandleDivide | 2592–2789 | 15 |
| HandleGather | 4634–4858 | 7 |
| Total | 1087 lines | 60 schemas |

I traced all 22 selected direct local call edges in the frozen typed inventory
for these five functions. The eleven distinct selected helper names were read:
IsAll (int8 overload), ReplaceInstructionIfCompatible (single instruction),
IsAllFpConstantPowerOf2, SwapCopyBitcastCopy,
BitcastingOperandOfReshapeOrCopyChain, ReplaceWithBitcast,
HasMatchDimensionTile, TryDivideToShift, InvertConstant,
GetPaddedDims and CheckPaddedDimsForGatherOfPad. I additionally read relevant
transitive local bodies: UnwrapToConstant, GetConstantValue, SameShape overloads,
ComputeBitcastDimMap, ValidateTilingOfBitcast, InvertBitcastDimMap and
ReshapeLayoutDimensions. Reading these bodies is not proof closure of their
external/virtual contracts.

No new native XLA build, Lean theorem or whole-checkpoint result is claimed by
this supplement. A small independent Python calculation checked the first
witness's [7,4] versus [8,4] arithmetic. The earlier independently rebuilt
2299-line/71-law v1 pilot result remains as recorded by the first report.

## P1 candidate: Scatter matching checks parameter opcodes, not parameter roles

At `algebraic_simplifier.cc:1105–1116`, each scatter flag requires a one-use
Scatter and reducer root `m::Add(m::Parameter(), m::Parameter())`. In frozen
`service/pattern_matcher.h:153–154`, Parameter() checks only the Parameter opcode;
the parameter-number overload is separately defined at `:3131–3141`.
Consequently the matcher also admits Add(p0,p0) and Add(p1,p1).

The single-rhs path at `algebraic_simplifier.cc:1248–1253` rewrites

```
A + Scatter_f(B, indices, updates)
  -> Scatter_f(A + B, indices, updates)
```

with the SAME update computation f. If f(current,update)=current+current,
A=[1,1], B=[3,3], index0 and update5, the unrewritten result is [7,4] while
the replacement is [8,4]. All arithmetic is small exact s32 arithmetic; there
are no collisions, exceptional floats, overflow or initializer assumptions.
The matcher does not require that both reducer parameters be used.

This candidate is not excluded by the documented Scatter contract:
`docs/operation_semantics.md:4759–4777` initializes output from the operand,
passes current value then update into update_computation, and explicitly
permits noncommutative update computations. Unlike Reduce's documented identity
premise, the inspected Scatter contract does not impose an Add(p0,p1) identity.
`ShapeInference::InferScatterShape:5003–5022` uses
`VerifyReducerShape:89–183`, which checks parameter/result shape signatures,
not distinct role usage in the root.

A concrete native replay candidate (not yet parsed/verified by this review):

```hlo
HloModule scatter_parameter_roles
update {
  current = s32[] parameter(0)
  incoming = s32[] parameter(1)
  ROOT twice_current = s32[] add(current, current)
}
ENTRY main {
  a = s32[2] parameter(0)
  b = s32[2] parameter(1)
  indices = s32[1,1] constant({{0}})
  updates = s32[1] parameter(2)
  scattered = s32[2] scatter(b, indices, updates), update_window_dims={}, inserted_window_dims={0}, scatter_dims_to_operand_dims={0}, index_vector_dim=1, to_apply=update
  ROOT result = s32[2] add(a, scattered)
}
```

Proposed census correction: preserve the actual matcher, and split/annotate all
four `HandleAdd/scatter-*` schemas by reducer roles 00/01/10/11 (and both reducer
role selections when there are two scatters). Do not silently strengthen the
source guard to roles01/10. Existing `dependencies` mentions parameter identities;
this witness turns that open dependency into a concrete testable partition.

Next validation: verify the original HLO, evaluate no-pass/direct-handler/full-
pass profiles with the same small inputs, inspect actual before/after reducers
and operands, and verify replacement HLO. Include roles01/10 controls, lhs/rhs
orientations, layout-sensitive skip and one-use failure controls. A small
kernel-checked modular/integer Scatter certificate can refute the explicit
update contract after the native/source bridge is checked. Do not call it a
confirmed compiler defect or accepted source refutation before those steps.

## P1 candidate: small-Gather unrolling can cross an index-type literal boundary

`HandleGather:4656–4686` permits a rank-one operand up to the configurable
very_small_gather_size, implicit trailing index-vector dimension and one
collapsed slice dimension. It emits comparisons `index >= MakeScalarLike(index,i)`
for every i from0 to operand_extent-1. No representability guard is present.
The default option is4 (`algebraic_simplifier_options.proto:72`), but the option
is an unrestricted int64 field in the inspected declaration.

`ShapeInference::InferGatherShape:4571–4584` allows integral index tensors.
`service/hlo_creation_utils.h:333–339` constructs the int64 scalar literal and
converts it to the base index element type. `Literal` conversion at
`literal.cc:1834–1881` clamps floating-to-integer conversions but uses
static_cast for integral-to-integral conversions. On the C++ signed narrowing
profile used by the recorded host, converting128 to s8 yields -128.

Therefore a concrete replay candidate is:

- Operand s32[129] containing labels0 through128.
- Index s8[1] containing0.
- Gather: index_vector_dim=1, collapsed_slice_dims={0}, start_index_map={0},
  offset_dims={}, slice_sizes={1}; expected original result s32[1] containing0.
- Configure very_small_gather_size=129. The final generated comparison uses
  s8(-128); `0 >= -128` selects label128, unlike the original label0.

This is an inspected conversion/branch calculation, not a native verifier/pass
result or a Lean proof of C++ conversion. Default threshold4 does not reach this
branch for a 129-element operand; that control is essential. Existing
`HandleGather/small-select-chain` already records the missing representability
check as an open dependency, so this is a concrete proposed witness, not a newly
missing lexical site.

Proposed correction: record index dtype/width, option threshold, extent and
literal representability as distinct semantic partitions. For the safe case,
prove that the monotone Select chain implements lower/upper clamping when every
i is represented exactly. For the boundary case, perform verified-HLO native
control/handler/pass replay, explicitly record the conversion and comparison
interpretation, and add a kernel-checked finite-word witness if confirmed.
Use threshold4/128 controls, s32 indices, extent128, and negative/high indices.
Never exclude configurable thresholds merely because the default is small.

## P2 outcome gap: allocation before a failed compatibility attempt

`HandleConcatenate:2120–2132` allocates a clone when two or more nonempty operands
remain, then calls ReplaceInstructionIfCompatible, discards false and returns.
`:2204–2229` similarly allocates merged slices and a concatenate clone before
that compatibility attempt. The helper at `:861–882` rejects an old node with
control predecessors before touching the replacement.

Consequently a control-predecessor witness can retain the old root while new
unused nodes were added. The AddInstruction calls do not themselves invoke
visitor MarkAsChanged in these bodies, and the rejected compatibility helper
does not mark it either. Thus graph allocation may coexist with unchanged root
and changed()==false. That last flag outcome still needs actual visitor replay,
including full-pass interactions. It differs from the separately diagnosed
new-instruction wrapper which marks changed on an OK-status skip.

The frozen rows correctly contain returns_even_if_compatibility_fails=true, but
their success guards require compatibility succeeds. Proposed correction: add
attempt/outcome/frame records for post-allocation skip; do not count these as
new semantic rewrite obligations until the observation contract settles the
unit. Audit root/uses, allocation counts, control edges, changed flag and status,
not only tensor values. Suggested witness: Concat(parameter[1],parameter[0],
parameter[1]) with an explicit control predecessor on the concat; use the same
input without that edge and a unary concat as controls.

## Per-handler path reconciliation and remaining obligations

### HandleAdd

1. `:932–940`: rhs then lhs IsAll zero forwarding; failed compatibility continues.
2. `:943–949`: direct Constant-left canonicalization returns the status of the
   new-instruction wrapper. Allocation/default relay outcomes are separate from
   the arithmetic commutativity law.
3. `:959–998`: two constant-gathering families, direct versus broadcast/scalar;
   require non-floating/non-complex or fast math, allocate constants/broadcasts
   before final replacement, and propagate MakeBinaryHlo status.
4. `:1001–1011`: AddAnyOrder cancellation with pointer equality and integral/
   fast-math guard; compatibility false continues rather than terminating.
5. `:1033–1058`: partial-update rewrite uses the original DUS start operand
   span for both DynamicSlice and replacement DynamicUpdateSlice. The source
   has no local fast-math guard; index-clamp, floating signed-zero/NaN and
   source storage/effect contracts remain explicit.
6. `:1077–1095`: shared-factor matching, both products one use, integral or
   floats-are-real or scalar power-of-two permission. Power-of-two recognition
   uses GetConstantValue/frexp, not an all-real arithmetic contract.
7. `:1098–1261`: layout-sensitive mode exits before scatter handling. The two
   scatter flags include one-use and root pattern checks. If both are true,
   rank mismatch, batching-size mismatch, more than one unequal index axis,
   scalar sentinel or failed cheapness returns from the handler. It does NOT
   fall through to the single-scatter paths on those failures. Concat safety
   tests all six dimension-number fields, index type and update window sizes,
   sorted/unique flags. Its failure uses nested Scatter mutation, not no-op.
8. `:1242–1259`: nested path mutates rhs base, then lhs base, then replaces Add;
   one-scatter paths mutate the selected base then replace Add. Error/skip after
   an earlier successful operand write requires a continuing-state contract.

Ordinary pointer captures are less mysterious here than the generic ledger
warning suggests. Top-level Match (`pattern_matcher.h:196–208`) preflights with
capture=false. A failed structural match does not commit ordinary capture
pointers. The only later pattern writing the original lhs/rhs is the partial-
update pattern, whose successful match returns immediately. Thus factor/scatter
handling retains the initial lhs/rhs roles. Successful matches followed by failed
extra conditions may retain other captures; arbitrary WithPredicate callbacks
(e.g. UniqueHloInstruction:289–314 elsewhere) are not made pure by this argument.

Remaining: reducer-role witness/partitions; full scatter collision/order and
index batching semantics; finite count arithmetic and dtype promotion;
floating family permissions; compatibility/new-node API frame and status paths;
source literal recognition and cross-instruction uses/control/metadata.

### HandleCopy

- First delegates to SwapCopyBitcastCopy; false continues. That helper refuses
  synchronous host transfers for both copies, traverses intervening bitcasts,
  constructs dimension maps, checks initial tiling and tries move-bitcast before
  move-copy. If the first tiling branch is chosen but its layout shape/virtual
  IsValidLayout test fails, it returns false; it does not try the second branch.
  Successful branches allocate an inner node and CHECK_OK the outer replacement.
- Nested-copy composition precedes the sharded-entry-root guard. That guard
  applies only to the ordinary compatibility removal, not globally to all Copy
  simplification.
- Chain-to-bitcast is locally suppressed by a layout-sensitive endpoint memory-
  space difference. Later branches have their own conditions; the memory-space
  exclusion is not a global Copy-handler condition.
- Copy(Reshape) clone requires one use, logical ReshapeIsBitcast and explicit
  match-dimension/tile checks. The reorder branch is layout-sensitive and needs
  AlignLayouts/UpdateLayout. The rewrite Boolean is
  (!old_hardware && new_hardware) ||
  (copy_before_present && (!old_hardware || new_hardware)).
- Reorder uses ArraySize totals and `10*before/9`; overflow/range must be covered.
  Copy omission specifically uses equality ignoring memory space; output uses
  Bitcast iff new hardware-bitcast is true, otherwise Reshape. Preserve the four
  provisional construction cases and old/new hardware/copy-presence outcomes.

Remaining: backend IsValidLayout/TargetReshapeIsBitcast/UpdateLayout and
AlignLayouts contracts; host-offload semantics; full tiled/packing/memory-space
observations; map/product bounds and indexing invariants; frame/error behavior.
The untiled dense transpose theorem is not this entire Copy contract.

### HandleConcatenate

- Unary branch calls compatibility then returns even on false.
- Empty filtering runs before layout sensitivity; “zero elements” need not mean
  zero concat-axis extent. The all-empty replacement may fail SameShape.
- Flattening requires layout-insensitive mode and a changed flattened operand
  count. It returns a new instruction via default-false relay.
- Adjacent-slice merging scans maximal consecutive shared-input unstrided runs;
  equal nonconcat extents plus equal starts imply equal other limits under legal
  input. The merged shape/layout and retained limits/strides need a coordinate
  proof. Multiple merged nodes may exist before final replacement is rejected.
- With two scalar Broadcast operands, low-pad has priority over high-pad.
  Repeated-pointer/extent-one broadcast elimination is later, so earlier pad
  matches can suppress it. The MakeReshapeHlo result is unwrapped via .value().

Remaining: generic concat/pad/index laws, legal empty/dynamic shape partitions,
allocation/skip/change outcomes, constructor/error/unwrapping contracts,
metadata/control/alias and layout effects.

### HandleDivide

- One forwarding then integral primitive power-of-two helper comes first.
  Signed helper accepts positive single-bit divisors and uses sign comparison,
  modular negation, logical right shift and sign restoration; signed minimum
  input cannot be modeled using ordinary absolute value without word semantics.
- Exp pair and exp denominator require fast math. Power denominator has a local
  nonintegral guard but NO fast-math guard; Sqrt/Rsqrt denominator rewrites also
  lack one and require one use.
- Integral output returns before all later reciprocal/fraction rules.
- Constant inversion has direct/broadcast cases, floating/complex primitive
  dispatch, host NativeT reciprocal and rebroadcast preservation. It is not
  guarded by fast math in this source. Inversion/population errors propagate.
- CPU broadcast reciprocal explicitly requires executing_on_cpu,
  enable_sink_broadcast, enable_fast_math and one use of the inner input.
- Fraction, nested numerator, nested denominator and predicate/scalar-broadcast
  rules follow with no local fast-math check; do not copy the CPU rule's guard
  to them. Each may allocate through status-returning creation utilities before
  the final existing-instruction replacement.

Remaining: finite division/shift/predicate word laws; host reciprocal rounding
and complex exceptional/branch behavior; family-specific allowed error contracts;
shape/broadcast matching, source typed promotion and every creation/API frame.
An exact F32 probe such as parameter7 / constant3 versus parameter7 * rounded
reciprocal3 would be useful, but a bit difference alone must be judged against
an adopted numerical observation contract. No such probe was run here.

### HandleGather

- Empty operand returns a zero-like result before effective-scalar handling;
  legality/definedness of empty/collapsed output profiles must be established.
- Effective scalar has separate rank-zero versus all-unit reshape cases.
- The small Select chain follows; it initializes element0, then loops from0
  again. There is no layout-sensitive guard on this path. Index literal width
  is the concrete missing semantic partition described above.
- Pass-through maps come from external GetGatherOperandPassthroughDims. The Pad
  helper accepts each padded axis only as pass-through or explicit batching;
  batching requires equal paired index-pad configs and no extra index-padded
  axes. Its failure returns before extending either mapping; extension occurs
  only after checks succeed. A successful batching rewrite drops the outer
  index Pad and copies mapped padding to result axes.
- The reshape-Pad path requires logical ReshapeIsBitcast, every padded axis to
  survive reshape unchanged, and the mapped axis to be a Gather pass-through.
  Scratch map operator[] calls can insert entries before a failed Boolean guard;
  those are local data-structure writes, not independent HLO rewrites. The final
  conjunction must retain that distinction in any extraction.

Remaining: complete Gather clamp/batching/offset semantics and attribute
invariants; small-index/threshold witness; pass-through and explicit-batching
mapping implementation contracts (the frozen snapshot includes their headers,
not those .cc implementations); Pad/crop/interior padding and reshape laws;
finite shape/index arithmetic and graph/API effects.

## Residual coverage and next bounded work

Cumulative full-body reading is now 48/58 Handle-prefixed definitions (47 actual
visitor overrides plus the shared helper), but none is accepted as a complete
source proof. These TEN large bodies from the original request remain only
partially read/screened: HandleBroadcast, HandleCompare, HandlePad, HandleReshape,
HandleSlice, HandleDynamicSlice, HandleDynamicUpdateSlice, HandleReduce,
HandleReduceWindow and HandleTranspose. Their exact line ranges remain in the
first report. Other helper closures, external declarations and backend overrides
remain open as before.

Recommended immediate follow-up is native/Lean replay of the two small concrete
candidates and the Concatenate allocation/changed-flag control. Then continue a
separate bounded semantic review of the ten remaining large bodies, retaining
all earlier review results and scope boundaries. The five-handler success/case
records below remain unclosed; their count must not become a proof denominator.

### Open source-case IDs from arithmetic-cases.json

- `HandleAdd/rhs-zero`
- `HandleAdd/lhs-zero`
- `HandleAdd/constant-right`
- `HandleAdd/constant-sum-direct-constants`
- `HandleAdd/constant-subtract-direct-constants`
- `HandleAdd/constant-sum-broadcast-scalars`
- `HandleAdd/constant-subtract-broadcast-scalars`
- `HandleAdd/cancel-subtract-lhs`
- `HandleAdd/partial-update-lhs`
- `HandleAdd/cancel-subtract-rhs`
- `HandleAdd/partial-update-rhs`
- `HandleAdd/factor-lhs-lhs`
- `HandleAdd/factor-lhs-rhs`
- `HandleAdd/factor-rhs-lhs`
- `HandleAdd/factor-rhs-rhs`
- `HandleAdd/scatter-concat`
- `HandleAdd/scatter-nested`
- `HandleAdd/scatter-single-rhs`
- `HandleAdd/scatter-single-lhs`
- `HandleDivide/one`
- `HandleDivide/power-two-unsigned`
- `HandleDivide/power-two-signed`
- `HandleDivide/exp-pair`
- `HandleDivide/exp-denominator`
- `HandleDivide/power-denominator`
- `HandleDivide/sqrt-denominator`
- `HandleDivide/rsqrt-denominator`
- `HandleDivide/constant-direct`
- `HandleDivide/constant-broadcast`
- `HandleDivide/broadcast-reciprocal`
- `HandleDivide/fractions`
- `HandleDivide/nested-numerator`
- `HandleDivide/nested-denominator`
- `HandleDivide/predicate-scalar-broadcast`

### Open source-case IDs from layout-cases.json

- `HandleCopy/swap-delegation`
- `HandleCopy/compose-identity`
- `HandleCopy/compose-copy`
- `HandleCopy/compatible`
- `HandleCopy/chain-bitcast`
- `HandleCopy/reshape-clone`
- `HandleCopy/reshape-reorder-new-copy-reshape`
- `HandleCopy/reshape-reorder-new-copy-bitcast`
- `HandleCopy/reshape-reorder-omit-copy-reshape`
- `HandleCopy/reshape-reorder-omit-copy-bitcast`

### Open source-case IDs from tensor-index-cases.json

- `HandleConcatenate/unary`
- `HandleConcatenate/filter-all-empty`
- `HandleConcatenate/filter-one-nonempty`
- `HandleConcatenate/filter-many-nonempty`
- `HandleConcatenate/flatten`
- `HandleConcatenate/adjacent-slices`
- `HandleConcatenate/pad-low`
- `HandleConcatenate/pad-high`
- `HandleConcatenate/repeat-unit-axis`
- `HandleGather/empty-input`
- `HandleGather/effective-scalar-rank-zero`
- `HandleGather/effective-scalar-unit-array`
- `HandleGather/small-select-chain`
- `HandleGather/pad-hoist-passthrough`
- `HandleGather/pad-hoist-batching`
- `HandleGather/reshape-pad-hoist`

