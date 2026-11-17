# Independent Pilot mixed-role review

## Scope and gate

This is the read-only review of the 19 `TensorRewrite/Pilot` paths in
`frozen-cases.json`. The overall gate covers 42 paths; this worker owned exactly
the 19 Pilot paths. I read the repository instructions, audit gate, frozen case
list, actual source declarations/imports, the prior closure inventory's consumer
lists, and representative maintained and packet call sites. The row-by-row
record is [pilot-review.json](pilot-review.json).

All 42 frozen source hashes were recomputed and matched their manifest values;
the 19 output rows match the frozen Pilot paths in order. The checkout is at
`361c64701417afaabb1c09d046bf26e3b6ed379c`. No Lean source, packet, pin, or
semantic definition was changed. No builds or theorem replays were run.

Pilot role counts: 6 semantic model, 3 generic or operation-specific helper,
1 rewrite-specific proof, and 9 mixed. These labels describe the inspected
module surfaces; they do not claim every declaration or transitive import was
semantically audited.

## Higher-risk findings

### BroadcastAxes admits more than the HLO attribute contract

`TensorRewrite/Pilot/IndexMaps.lean:16-25` gives `BroadcastAxes` a vector of
signed integers and checks only nonnegativity and `< outputRank`. It does not
encode strict ordering or uniqueness. A concrete model value such as axes
`[0, 0]` (with sufficient output rank) or `[1, 0]` therefore meets this record's
field condition. `broadcastIndex` at lines 27-32 projects each input coordinate
from its decoded output coordinate, subject to a caller-supplied exact extent
equality. The theorem is well-defined for those values, but those malformed
axis lists must not be presented as valid HLO broadcast attributes.

The XLA HLO broadcasting documentation says the broadcast dimensions must be
strictly increasing, which entails uniqueness. This is an external source
contract, not a fact represented by the Lean record: [XLA broadcasting
semantics](https://github.com/openxla/xla/blob/main/docs/broadcasting.md).
StableHLO has had distinct ordering semantics, so this observation is specific
to the HLO contract and should not be generalized to every dialect.

Two actual callers illustrate the boundary:

* `comparisons/tensorright-v1/Iota.lean:28-35` proves coordinate preservation
  for an arbitrary `BroadcastAxes`; it assumes only the extent equalities.
  `Iota.lean:37-90` defines and proves composition by decoding and re-encoding
  two such maps, constructing a new range-valid record. This proves closure of
  the *range-only model* under composition; it does not establish that either
  input map or the composition came from valid HLO attributes.
* `TensorRewrite/Theory/UnitAxis.lean:57-69` constructs axes from the recursive
  retained-axis map. `UnitAxisLemmas.lean:70-84` proves decode equals that map
  and proves matching extents. This constructor's retained positions preserve
  source order by construction, unlike the unrestricted public record. That
  useful invariant is specific to this caller and is not lifted into
  `BroadcastAxes` itself.

Other consumers include `ControlValues`, `BroadcastWindowTarget`,
`ScatterBatching`, and the Iota/Broadcast packets. Their type-level acceptance
of arbitrary `BroadcastAxes` means the Lean model surface is broader than HLO
attribute validity unless a caller supplies or derives additional guards.
The current model also requires exact mapped extent equality (`IndexMaps.lean:30`),
which is its own modeling choice and should be compared with the exact opcode
contract before claiming source coverage. No C++ parser/verifier or source
correspondence proof was inspected here.

Assessment: this is a real model-boundary omission, not a circular proof or a
hidden assumption in the coordinate lemmas. A safe follow-up could add a
separate `BroadcastAxes.IsOrdered` (or injective/strictly-monotone) predicate
and require it only in HLO-faithful packets/constructors, preserving the
range-only abstraction for mathematical callers that need it. Do not silently
strengthen all existing theorems: first determine which packets intend HLO
versus StableHLO, and add explicit negative examples for duplicate and reversed
axes. This review did not implement that change.

### SliceShape combines a foundation with rewrite formulas

`TensorRewrite/Pilot/SliceShape.lean:15-36` contains the foundational `Axis`,
count formula, and `IsWellFormed` predicate. Lines 38-53 then place
`removeRedundantStride` and `reorderReverse`, which encode two concrete rewrite
transformations, in that same base module. These are not generic slice
well-formedness operations. `EmptySliceRefutation.lean:21-55` is their only
maintained direct caller found by repository-wide search and uses them to show
that a legal empty input can become a non-well-formed one-element output.
`comparisons/tensorright-v1/ReverseSliceFailure.lean:3-4,21-44` imports the
base module for the axis/validity language and separately defines the paper
replacement formula.

This is an actual mixed-role boundary and a mild dependency-layering oddity,
not evidence that the formulas are wrong. A future isolated cleanup could move
the two transformations into `TensorRewrite.Pilot.SliceShapeTransforms`, leave
`Axis`/`IsWellFormed` in `SliceShape`, and update `EmptySliceRefutation` to
import both. Repository search found no other direct uses of those functions.
That split changes the frozen `SliceShape.lean` hash and dependent closure, so
it requires a new explicitly versioned audit baseline and targeted Lean
acceptance; it is not part of this read-only review.

### Other explicit target-specific seams

* `ConstantGuard.lean:15-24` hard-codes seven wrappers associated with the
  constant matcher; its module comment explicitly leaves decoding and bounded
  map construction to correspondence obligations. The soundness lemmas are
  clean consequences of the declared total map model.
* `DynamicIndexValue.lean:18-19` defines `evaluatorUnsigned64` as `BitVec.toInt`
  and labels this as the pinned evaluator behavior on the test host. It is an
  explicit environment-specific observation, not a generic unsigned conversion
  theorem. `DynamicIndexLemmas.lean:19-21` correctly limits signed/unsigned
  equality to the no-sign-bit-set premise.
* `Reduction.lean:5-7` states an ordered logical fold and separates floating
  reassociation/graph effects. `Contraction.lean:6-8` makes precision,
  conversion, and finish explicit. These are clear model boundaries, not hidden
  arithmetic assumptions.

I found no target rewrite equality assumed as a premise in the reviewed 19
module surfaces. This is a declaration-level inspection, not a full imported
closure audit.

## Consumers and inspection limits

Every row includes a maintained consumer and, where the frozen inventory
records one, a paper-packet consumer. High-fan-in public-facing modules were
prioritized: `IndexMaps` has multiple Theory consumers plus `Iota`; `Reshape`
and `Reduction` feed several algebra/operation modules; `ConstantGuard` feeds
the index and reshape constructors. Specific consumer links and declarations
are in `pilot-review.json`.

Limits: the audit covers exactly 19 of 42 mixed-role paths. The other 23 remain
for the coordinator/other reviewer. It does not audit all declarations in
transitive dependencies, verify upstream XLA C++ implementation behavior,
replay theorem axioms, prove source correspondence, inspect every downstream
packet in full, or support a blanket cleanliness claim for the 109-module
closure. The report does not recommend an immediate source edit.

## Effort record

Foreground source/caller inspection and report preparation completed in this
pass. Exact start time and active minutes were not instrumented, so no precise
duration is asserted. There were no worker waits, builds, retries, or parallel
effort to add to elapsed time.
