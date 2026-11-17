# Exact legality of two static slice-axis transformations

- IDs `RemoveRedundantStride/single-element-axes` and
  `TryToReorderSliceAndReverse/commute`.
- Baseline Git source `b5a3d0a77870fc832f1c66b0a50362c488313d12`. XLA
  pin `e58e523b11f1fde802a493a776d158007486e1bf`; the relevant retained
  helper bodies are in algebraic_simplifier.cc lines 7572–7652, with
  HandleSlice dispatch at 8102–8112.
- Frozen goal types in SliceShapeExactSpec.lean. Required targets are
  RemoveRedundantStrideShape and ReorderReverseShape. Auxiliary targets
  RemoveRedundantStrideCoordinate and ReorderReverseCoordinate compare
  input lookup coordinates when shape is preserved. Only the model's
  SliceShape import and pinned Lean 4.35.0 Std/library closure are needed.
- The input is any legal original static axis with its supplied declared
  extent. Stride removal applies the exact guard and includes its no-op
  path. Reverse is on an axis in the reverse mask; unselected axes are
  unchanged by construction in this model. Mathematical Int and truncation
  toward zero are inherited. This covers exact bounds/count and logical
  lookup for one axis, excluding signed overflow, full graph dispatch,
  arbitrary-rank tensor integration, dynamic extents, effects, layout and
  C++ correspondence.
- Preserve the old native witness/review record and the kernel certificates
  in EmptySliceRefutation. Replaying old evidence is reuse. Neither replay
  nor the new universal theorem establishes a fresh native-bug discovery.
- Proof worker owns files within this packet only; frozen specifications
  and pinned inputs are read-only for proof work. No subworkers, dependency
  downloads, or broader builds. Allowed axioms are propext, Quot.sound and
  Classical.choice. Compile frozen goals and focused controls without
  sorry/admit/native_decide. The model gate requires Lean proofs of the
  exact shape classifications, positive and negative controls and parent
  coordinated independent review. Unclosed coordinate or full-source
  work is recorded separately.
- Setup started at 22:33:51 UTC on 2026-11-17, with five-minute first
  compiler checkpoint and a ten-minute evidence-based decision.
