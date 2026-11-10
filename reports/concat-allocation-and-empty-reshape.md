# Concatenate mutation status and empty-axis DynamicSlice construction

XLA e58e523b11f1fde802a493a776d158007486e1bf, unchanged canonical pass SHA256
1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f.
Native diagnostics extend the source review without adding Lean declarations.
Accepted source rewrites remain zero; N/F and intended observation/domain
contracts remain open.

## Concatenate: rejected replacement can retain an allocation prefix

The handler filters empty operands before its layout-sensitive early return
(:2103–2133). With two surviving operands, it inserts a cloned concatenate and
then calls ReplaceInstructionIfCompatible. Adjacent unstrided slices similarly
insert a combined slice and a concatenate clone before that check (:2158–2242).
The helper rejects old control predecessors immediately (:861–880), with no
rollback of prior allocation. The caller ignores its false result and returns OK.

The native fixture uses data[2], empty[0] and other[2] parameters, a scalar marker,
and both layout modes. Five cases cover filter-many/filter-one/filter-all/unary
and adjacent-slice paths. Every original graph verifies. Initialized handler,
ordinary pass, fixed-point pass and no-pass controls distinguish statuses from
root identity, node deltas, exact control edges and evaluated values.

Of120 run/step records,15 report changed=false while retaining added nodes:
filter-many adds one node in either layout mode; adjacent-slice merging adds two
in layout-insensitive mode. All have old control predecessors and retain their
root and marker edge. Three direct-handler invocations repeat these additions.
The fixed-point pass returns false after one traversal, leaving the same prefix;
this is not the earlier generic new-instruction API's true-status/rerun-cap case.
Unary/filter-one/filter-all predecessor skips allocate nothing. All120 tensor
values are preserved and all output graphs verify. These deltas do not establish
a tensor-semantic failure: allowed dead allocation and mutation/status contracts
must be specified independently.

Successors differ from predecessors. Existing-instruction replacement explicitly
relays control dependencies (dfs_hlo_visitor_with_default.h:380–413). A successor
alone therefore permits replacement and preserves its ordering edge. For adjacent
slices, recursive unused-operand removal makes a successful handler delta−1,
rather than allocation count minus the old root alone. The whole-pass successor
profile ends at the original data parameter with delta−3: unreachable-root
traversal first reaches the old root through its successor marker, then the
computation visits its current root last and simplifies the new full slice and
unary concatenate. See hlo_computation.cc:2176–2189,2690–2703.

Archive: `reports/concatenate-status-replay-v3/`; contract and checked source spans:
`census/concatenate-status-contract.json`. The first failed fixture assumed the
successor was rejected and then reused a replaced pointer. The second omitted
recursive removal/current-root traversal from expected counts. Both failures are
preserved in v1/v2 and are not evidence of an uncontrolled pass crash.

## DynamicSlice: an empty inserted axis reaches a constructor CHECK

The unit-reshape branch (:8214 onward) initializes new input-axis slice sizes to1,
then copies sizes on unmodified non-unit axes. It does not require a deleted
output unit axis's requested slice size to remain1. For

```
x:s32[2] -> reshape:s32[1,2] -> dynamic-slice:s32[0,1]
```

it creates an intermediate dynamic-slice:s32[1] and attempts to reshape its one
element to zero elements. CreateReshape's static element-count CHECK rejects this
(hlo_instruction.cc:2506–2515). Four checked-death tests cover the initialized
handler and whole pass, each with runtime or constant indices. Constant-index
conversion occurs later in this handler and cannot preempt the unit-reshape path.

There are21 original-verifier/mode records: seven profiles with control/handler/
pass. Nonempty slices, empty retained axes and both-empty axes avoid the count
mismatch. Layout-sensitive mode skips this handler branch; the whole pass can
still report changed because the upstream Reshape becomes Bitcast. A separate
layout-sensitive all-constant profile reaches later constant conversion and
remains well formed. Handler priming suppresses both DynamicSlice and Reshape,
with unchanged status and exact graph required before the original handler.
No operator evaluation or backend execution is claimed.

The semantic domain needs an explicit decision. Pinned shape_inference.cc:
3587–3612 permits zero slice sizes, and the input HLO verifier accepts every
profile. The [pinned XLA prose](https://github.com/openxla/xla/blob/e58e523b11f1fde802a493a776d158007486e1bf/docs/operation_semantics.md#L2514)
requires positive slice sizes; [current XLA documentation](https://openxla.org/xla/operation_semantics#dynamicslice)
retains that restriction. [StableHLO's different IR specification](https://openxla.org/stablehlo/spec#dynamic_slice)
permits nonnegative sizes. That does not automatically transfer the StableHLO
contract to HLO. Record a reachable failure on verifier-accepted inputs and a
specification discrepancy; do not silently treat verifier acceptance as definitive
normative legality or strengthen the source guard to avoid the failure.

Archive: `reports/dynamic-slice-empty-reshape-replay-v4/`; exact contract/spans:
`census/dynamic-slice-empty-reshape-contract.json`. Failed v1 suppressed only
DynamicSlice during priming; layout-sensitive Reshape legitimately changed. Failed
v2 assumed constant conversion ran first, leaving a constant-index fatal profile
untrapped. Successful v3 is preserved; v4 repeats the same21 tests with metadata
explicitly saying verifier-accepted and semantic-domain-unresolved.

## Source enumeration and measurement

The new independent simple/scalar review adds106 exact local records,245 excerpt
hashes and106 function byte-interval hashes. It preserves two aliases and a legacy
Multiply direct pattern shadowed by the earlier returning constant-product stage.
Unique matcher-predicate state and sequential Select DUS captures are recorded as
source behavior without an unsupported unsoundness claim.

The reduction/collective review then adds77 records and228 excerpts, preserving
six aliases and a shadowed ReduceWindow subbranch. The Dot/convolution batch adds75
records and161 excerpts, correcting the constant-side interpretation of two frozen
suffix conventions and retaining continuing pointer rewrites/allocation prefixes.

Across six authenticated batches, the checked registry contains all488 current
local records and1447 excerpt hashes:448 action variants,35 call aliases,four
shared API contracts and one external source-call obligation. The count includes
all487 original frozen IDs and the separate scaled-DynamicSlice child. These are
source-lineage roles, not canonical N or verified coverage. The shadowed Multiply
record remains present with its explicit source-local reachability explanation.

Every supplied function-byte range, source excerpt/reference, replacement/
delegation anchor, predecessor stage and review/companion hash is checked.
Two older cases hash the named declaration lines without a separately wrapped
return type; newer review hashes cover the complete parser byte interval. Both
identities are checked against the pinned source rather than treated as equal.
Canonical alias targets/caller contexts, nonreplacement mutation/effect scope and
external interfaces still need independent reconciliation before N/F is frozen.

Custom Lean remains2763 lines: S776/H926/R691/A33/C337, with77 value laws and90
support lemmas. This milestone adds zero Lean lines or accepted proofs; native
fixtures, Python validation and source-review burden are separate. The byte comparison in
`reports/concat-empty-lean-continuity.json` checks every production Lean file against the prior clean-replay archive. That replay
still describes the unchanged proof sources; it does not replay
the new C++ fixtures or assert independent acceptance of the new source records.
The checkpoint includes68 Python tests, both native evidence validators, prior
Lean/axiom controls and existing source/API checks.

Next: complete canonical census and domain/observation review;
investigate remaining Dot/conditional-shape candidates; complete the diverse
reviewed pilot, full campaign, residual interventions and final independent replay.
These findings do not satisfy the final whole-workload feasibility gate.
