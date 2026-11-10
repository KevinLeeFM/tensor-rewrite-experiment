# Concatenation, broadcast, padding, dynamic indexing and Gather census

Source pin: e58e523b11f1fde802a493a776d158007486e1bf.
File: xla/hlo/transforms/simplifiers/algebraic_simplifier.cc.
Extractor/data: tools/extract_tensor_index_cases.py; census/tensor-index-cases.json.

## Checkpoint scope

This batch records 56 source schemas: Concatenate9, Broadcast13, Pad5,
DynamicSlice13, DynamicUpdateSlice9 and Gather7. It binds all 40 lexical
replacement sites in those six handlers. Four local helper records retain
source ranges, original-body hashes and inspected behavior, pending independent
semantic review.

At the initial core-indexing checkpoint, seven batches had 352 schema bindings, 275 distinct lexical
replacement candidates bound and 69 unmapped. Remaining candidates are concentrated
in Reduce/ReduceWindow, Dot/Convolution and their helpers, shared replacement
primitives and lexical declaration artifacts. This is discovery accounting,
not a complete semantic census or accepted-proof denominator. Complete profile
splitting and auxiliary/indirect effects still require reconciliation.

## Concatenate and broadcast

Concatenate records unary elimination; all-empty, one-nonempty and many-nonempty
filtering; same-axis flattening; adjacent unstrided-slice merging; both low/high
Pad conversions; and broadcasting repeated unit-axis operands. Compatibility
attempts can fail even though the handler then returns. In particular, zero total
elements do not imply that the first operand and concatenated output have equal
shapes. Records therefore require successful compatibility for a rewrite and
retain the early-return behavior separately.

Broadcast distinguishes sorted dimension maps with equal element count, equal-
rank transpose construction, inserted-unit reshape removal and the already
recorded elementwise-user helper with its caller option. Scalar broadcasts have
six concrete user classes: Reshape, Reverse, Transpose, non-tuple Sort, Slice and
DynamicSlice. Replacement changes that user's uses and calls MakeStaticShape;
dynamic-extent and metadata behavior remains an explicit obligation.

The scalar-operand branch returns even when it finds no qualifying user, so later
Iota, nested-Broadcast and degenerate-axis branches inherit a nonscalar operand
restriction. Only the last degenerate-axis branch inherits the later layout-
insensitive gate. Flattening all these paths under one global layout premise
would strengthen the source conditions incorrectly.

## Pad is also an in-place graph transformation

The Pad projection through a one-use Broadcast mutates its shape and dimension
list, clears sharding and updates layout, then constructs a smaller Pad and
restores the outer Broadcast. It also assigns the cloned Pad's padding config.
These four principal effect anchors are checked against original source text;
the three assignments must exist in the structural write ledger. Omitting the
sharding clear or an assignment cannot leave this evidence check green.

Other cases preserve the source distinctions between zero-element input,
irrelevant unit-axis interior padding, zero edge padding with compatibility,
and negative edges converted into nonnegative Pad plus Slice. The negative-edge
path restores the original result element type and copies layout before its
final shape check. Mixed types, finite integer arithmetic, tile handling and
error-path partial mutations remain obligations.

## Dynamic indices and copied data

Both dynamic handlers first exclude asynchronous computations. Their full-axis
index simplifications build zero operands using the first index's type and edit
the result of mutable_operands(). The frozen hlo_instruction.h:1313–1316 shows
that method returns InstructionVector by value. These are edits to a temporary
operand list before cloning, not direct writes to the original graph. A method
name alone is insufficient alias evidence.

DynamicSlice records scalar/full-shape elimination, selected Broadcast indices,
unit-reshape and transpose movement, constant-index static slicing, four Iota
scale/conversion paths and nested slice composition. The constant-index path
rejects negative constants even though runtime slicing clamps them. The Iota
multiplier matcher accepts a runtime scalar; its comment's word “constant” is
not a source guard. Index and result types, conversions and Iota extents remain
visible rather than converted into an arbitrary integer-real identity.

DynamicUpdateSlice records three source index-encoding paths for Pad conversion,
the host-offloading exclusion, full update elimination, low/high padded-region
concat replacement, full-axis zero indices, empty updates and nested composition.
Legacy tuple/concatenate index forms must still be reconciled with actual HLO
legality; their appearance in source is not proof that each yields a reachable
obligation in the final corpus.

Both nested compositions first change a data/update operand once and then write
each combined index inside a rank-dependent loop. Their schemas group the two
static call sites, retain this multiplicity and preserve FitsInIntegralType
checks, clamping and inner-to-outer index conversion. A rank-one example would
not verify that loop for every rank. A control removes the loop context while
keeping the call identity and is rejected.

## Gather

Gather records zero-element and effective-scalar inputs, the small-operand Select
chain, two direct Pad hoists and reshape/Pad hoisting. The small-chain construction
uses index literals at every iteration and has no local guard proving those
literals fit the index type; finite-width correspondence cannot be assumed from
the integer loop alone.

CheckPaddedDimsForGatherOfPad distinguishes pass-through axes from explicit
batching axes. Padded batching axes require corresponding index padding with
identical configs and no extra index-padded axes. Only the batching branch removes
the index Pad. Result extents, slice sizes and remapped low/high/interior padding
are kept in the source description. The reshape path additionally requires each
padded axis unmodified by the reshape and mapped to a Gather pass-through axis.
External sharding utilities, dimension-map invariants, sorted-index attributes
and actual Gather clamping semantics still require contracts and review.

## Validation and measurement

All 25 Python tool/evidence tests and the integrated checkpoint pass. New checks
cover complete selected-handler lexical coverage, per-axis versus once-only
mutation context and auxiliary Pad graph writes. Existing omitted-site,
false-acceptance, syntax-normalization, kernel proof and native archive controls
remain checked. No new native pass run or Lean theorem is claimed here.

Lean size remains S148/H66/R172/A9/C106, total501, with zero accepted full-source
rewrites. Current aggregate status is in README.md. Complete the remaining
source census, source/shape/type/graph contracts and independently reviewed
obligations before the scored campaign or a whole-file feasibility verdict.
