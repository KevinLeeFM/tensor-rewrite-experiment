# Independent review: F32/BF16 convolution promotion counterexample

## Verdict

**Accept the frozen mathematical-model counterexample.** The pinned source's shape inference and verifier admit the F32 lhs / BF16 kernel / BF16 preferred-result type combination, and the selected base-dilated convolution satisfies the promotion helper's false/convert-to-F32 branch after the stated option and earlier-branch conditions. The Lean counterexample is valid for the explicit nonnegative-integer BF16 round-to-nearest-even model. This does **not** establish a native pass execution, a complete C++ refinement, a backend-observable IEEE violation, or a full convolution-rule result. The finite witness is source-shape/gate reachable by code inspection; the rounding/conversion mapping remains an explicit model assumption.

## Source and HLO verifier audit

The packet SHA manifest passes and its source hashes match the bundle manifest for XLA commit `e58e523b11f1fde802a493a776d158007486e1bf`.

The prompt's `CheckOperandElementTypes` name is not present in this pinned source tree. The operative verifier path is `ShapeVerifier::HandleConvolution` (`hlo_verifier.cc:474–487`): it calls `ShapeInference::InferConvolveShape` with the declared result element type as `preferred_element_type`, then checks the inferred shape. FPROP shape inference (`shape_inference.cc:2436–2639`) validates arrays, rank/dimension-number permutations, positive group counts, feature divisibility, window size and the grouped feature relations. It does not require lhs and kernel element types to be identical; for FPROP it returns the explicit preferred element type when provided. Thus U32-like dimension logic aside, the packet's F32 lhs, BF16 rhs and BF16 preferred output are not rejected by shape inference.

The shape verifier's `CheckShape` calls `CheckMixedPrecisionOperands` when `allow_mixed_precision` is false. That helper (`hlo_verifier.cc:2670–2715`) explicitly allowlists `kConvolution`, so this opcode is exempt from the generic mixed-floating-operand rejection. With mixed precision enabled, ordinary result-shape comparison permits BF16/F32 precision compatibility; here the preferred result is already BF16, so the inferred and declared result element type are exactly BF16. I found no further convolution operand-element-type check in this verifier path. The profile's mixed input/output typing is therefore statically admissible under the pinned verifier, including the default non-mixed-precision option.

## Promotion branch and precedence

`HandleConvolution` (`algebraic_simplifier.cc:11223–11264`) first runs optional `ScalarMultiplyReduction`, then empty-array replacement, input-pad fold, filter-pad fold, and operand swap. The packet disables scalar reduction and operand swap; parameter operands avoid both pad-fold matches; all shapes are nonempty. CPU execution and oneDNN support are enabled, and the result type is BF16, satisfying the promotion helper's entry guard.

`PromoteConvolutionToF32IfNotOnednnCompatible` (`algebraic_simplifier.cc:10904–10989`) starts with `can_rewrite=true`; it rejects zero arrays, incompatible group/rank/window configurations, and specifically any `base_dilation != 1`. The packet uses base dilation 2, so the helper enters its promotion path. It inserts `Convert` operations for both operands to F32, clones the convolution with an F32 result, converts that result back to the original BF16 type, replaces the original convolution, and sets the caller's convolution pointer to the F32 clone. `HandleConvolution` then proceeds to later simplifiers. The same base dilation prevents the documented conv-to-dot/conv-to-multiply paths from representing this geometry; regardless, the packet's mathematical comparison is explicitly for the immediate promotion replacement and is not a pass-level run.

## Geometry, evaluator and scalar conversions

For NCW-style dimensions, the frozen shapes are input F32[1,1,2], filter BF16[1,1,1], output BF16[1,1,3], feature and batch group counts 1, filter window size 1, stride 1, zero padding, base dilation 2, window dilation 1, no reversal. Shape inference checks `inputFeatures / featureGroupCount = kernelInputFeatures`; here `1/1=1`, and output/kernel feature divisibility and batch divisibility hold. `InferWindowOutputShape` yields spatial extent 3: the two-element input dilated by 2 has bound 3, and a unit window/stride returns all three positions. The sampling model correctly selects input index 0 at output 0, the dilation hole at output 1, and input index 1 at output 2.

`HloEvaluator::HandleConvolution` (`hlo_evaluator.cc:6492–6677`) first converts operands whose type differs from the result to the result type, then chooses `GetElementwisePrimitiveType`; BF16 has width under 32 and therefore computes elementwise in F32. It converts these result-typed operands to F32 for accumulation and converts the final literal back to BF16. For the old graph, the F32 lhs therefore undergoes F32→BF16 rounding before F32 accumulation. The promotion graph's F32 lhs conversion is identity; the BF16 filter widens exactly to F32; the F32 result is then converted to BF16.

The pinned `LiteralBase::Convert` implementation (`literal.cc:1834–1948`) routes through a native `static_cast` for F32-to-BF16. The packet models this as conventional BF16 round-to-nearest-even. That underlying scalar conversion policy is not independently established by this Lean proof or a native run; it remains a stated model assumption. The witness uses small nonnegative integer values: input 257 with BF16 filter 3 gives `bf(257)=256`, so the old output is `bf(256*3)=768`; promotion computes `257*3=771` in F32 and rounds to `772`. The two products and the F32 additions are exact integers. The hole output is 0 on both sides, and the third output is 776 on both sides, as confirmed by the packet's Lean controls.

## Fresh Lean replay and evidence limits

I freshly ran only the packet-local Std modules with the pinned Lean binary, no Lake or package setup:

```sh
env LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/conv-bfloat-promotion/replay.py
```

The SHA checks passed. Lean 4.35.0 (commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`) compiled `PromotionSpec` (0.471 s), `PromotionProof` (0.324 s), and `PromotionControls` (0.288 s), each with exit code 0. The refutation reports `[propext]`; no `sorry`, `admit`, or new axiom is present. Total shell wall time was 1.122 s. I made no native run or build.

For this review, the current packet hashes are: `PromotionProof.lean` `c3485f34d6f9c6d33a3ced4a68cda7e423df00f291adda6666531325970f3a48`, `PromotionControls.lean` `d3861f5cc0adb6e116237edca7fbf7e7a3a02bc374001918cf2250df1c70756d`, and `replay.py` `01743bf12281dbc7ef74259433e72e4b4aa39edbfdab5b89aa38d66bf69ec2a2`. The initial SHA manifest freezes the spec, conditions and source files; it does not include proof/control/replay hashes, so these current review hashes identify the reviewed proof closure.

## Scope and timing

The Lean theorem refutes `Preserves` over the frozen finite abstract domain. It supports a source-shaped counterexample because the source shape and option/gate path are admissible, but no source implementation or backend observation claim is made. The BF16 cast formula, exact-real treatment of the small F32 integer arithmetic, and evaluation/profile correspondence are assumptions in this packet, not formal C++ or hardware proofs.

Review end: 2026-11-18 04:01:18 UTC. Start time was not captured at the first inspection; elapsed review was approximately seven minutes. Fresh compiler time: 1.083 seconds summed across Lean targets; shell wall: 1.122 seconds. No workers or other tests.
