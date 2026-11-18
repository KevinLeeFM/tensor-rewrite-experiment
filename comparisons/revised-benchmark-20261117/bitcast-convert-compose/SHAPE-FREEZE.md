# Frozen target: bitcast-convert inferred-shape mismatch

Only source shape inference and well-typedness are in scope. Arithmetic bit-stream preservation is historical algebra and is not replayed here.

## Pinned evidence

XLA source tree identified in `sources/manifest.json`: openxla/xla commit `e58e523b11f1fde802a493a776d158007486e1bf`; inspected current bundle corresponds to audit source ledger `d3a90a78d8aef76674aa42453f737f2b36d5b3d3`. `shape_inference.cc:612–667` contains `InferBitcastConvertShape`: equal complex-vs-real category, array operands, storage-bit-width divisibility; narrowing appends a minor dimension equal to the width ratio; widening deletes the final static dimension only when it equals the ratio. `ShapeVerifier::HandleBitcastConvert` runs this inference and checks the declared shape. At simplifier lines 1899–1910 the direct replacement is constructed using the original outer result shape. `HloComputation::ReplaceInstruction` checks compatibility with the replaced outer instruction, not inferred shape.

## Exact frozen cases

Represent a static array shape by a list of natural extents. Restrict the model to the unsigned integer storage widths U32/U16/U8 (32/16/8 bits); all are arrays and have the same non-complex category. Freeze the source shape-inference calculation:

1. Original inner: infer U32[] → U16 = `[2]`.
2. Original outer: infer U16[2] → U8 = `[2,2]`.
3. Direct replacement: infer U32[] → U8 = `[4]`.
4. Refutation: `[4] ≠ [2,2]`, so the direct conversion is not well-typed at the original outer result shape under this verifier rule.

The theorem target is `nestedShapeInference` in `ShapeInference.lean`, which proves all four facts by evaluating the exact finite source-width/shape calculation. The target is a source-guided well-typedness model, not a full C++ refinement or a claim about pass acceptance/runtime behavior.

## Controls and scope

The source function's divisibility/rank cases are encoded, but only the three widths and static shapes above are exercised by the theorem. The direct `BitcastCompose.lean` historical byte-stream theorem remains an uncompiled, excluded artifact; it is not imported. No actual HLO pass, native evaluator, dependency package, or cache is used. Fresh closure is packet-local `ShapeInference.lean` plus Lean's pinned `Std`.
