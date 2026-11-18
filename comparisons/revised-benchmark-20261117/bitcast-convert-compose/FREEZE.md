# Frozen case: nested bitcast-convert width composition

Status: Lean target frozen; model theorem pending compilation.

## Source and source observation

Source revision: audit ledger `d3a90a78d8aef76674aa42453f737f2b36d5b3d3`; `algebraic_simplifier.cc` SHA-256 `1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f`.
At `algebraic_simplifier.cc:1899–1910`, the handler removes an outer `kBitcastConvert` whose operand is another `kBitcastConvert`, creating one conversion from the original operand to the outer node's result shape. `shape_inference.cc:612–667` checks arrays, compatible complex-vs-real class, integral storage-width ratio, and static final dimension equal to the ratio when widening the element width; narrowing appends the minor ratio dimension. `ShapeVerifier::HandleBitcastConvert` checks the inferred shape. The instruction verifier delegates to shape verification. HLO evaluation delegates to `Literal::BitcastConvert`.

For U32 scalar -> U16[2] -> U8[2,2], both conversions are shape-inferred: narrowing appends dimensions 2 then 2. But a direct U32 scalar -> U8 conversion has inferred result U8[4], not U8[2,2]. The simplifier code retains the outer result shape `[2,2]` when creating the direct op. Thus this concrete chain exposes a shape/well-typedness concern: the direct replacement shape is not the shape inferred for a direct conversion. This packet does not infer whether a surrounding pass later repairs or rejects it, and makes no source bug claim.

## Exact frozen model target

Use exact stored words and one consistent `leastFirst` physical bit order. For `input : Words 1 32`, let `h₁ : 1*32 = 2*16` and `h₂ : 2*16 = 4*8`. The frozen primary proposition is:

`repack leastFirst leastFirst h₂ (repack leastFirst leastFirst h₁ input) = repack leastFirst leastFirst (h₁.trans h₂) input`.

This is equality of the four output 8-bit words / complete physical bit stream. The nested view arranges these cells as U8[2,2]; the direct source-inferred view arranges them as U8[4]. It is not equality of differently ranked tensor values. The model is well-typed byte-stream reinterpretation only; it assumes a single fixed cell order/within-word bit order and does not formalize source-language aliasing, device endianness, tiled storage, memory effects, execution, or C++ correspondence.

## Frozen controls

1. Reverse U8[2,2] -> U16[2] -> U32[] using reciprocal width-count equalities and require the round trip to recover the original word exactly.
2. Same-width/same-order `repack` is identity.
3. Rank/shape control: rank `[2,2]` is 2 and `[4]` is 1; they are different tensor shapes, so the stream theorem cannot be used as a same-result-type rewrite proof.

No counterexample to bit-stream composition is expected; the source-level shape compatibility concern is a separate structural finding. The exact statements and code are in `BitcastCompose.lean`. No theorem is accepted until targeted Lean replay and axiom/freeze checks pass.
