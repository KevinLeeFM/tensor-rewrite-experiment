# Index-equality proof plan and bounded prerequisite

Frozen goal and all 28 manifest hashes are unchanged. This checkpoint is a proof plan plus an unreviewed generic prerequisite, not a proof of the index equality or `Goal`. The outer-rank requirement remains a model restriction, not an established source invariant. No C++ correspondence or speedup is claimed.

## Rank-independent coordinate argument

The plan's checked permutation and `moved_before_split` make the moved axis `m` strictly earlier than split axis `s`. Write the input shape as `P ++ [A] ++ M ++ [C*W] ++ S`, where `P`, `M`, and `S` are arbitrary lists of extents, including empty lists; `A` is the original moved-axis extent, `C` is chunk count and `W` is chunk width. The inner shape is `P ++ [A] ++ M ++ [C,W] ++ S`. The pinned permutation moves `C` to immediately before `A`, giving `P ++ [C,A] ++ M ++ [W] ++ S`. The replacement concat shape is `P ++ [C*A] ++ M ++ [W] ++ S`.

Their row-major linear positions match under merging adjacent `C` and `A`: for the same position, decompose the merged coordinate as `(c,a)` with `c = merged / A`, `a = merged % A`. The replacement reads source axis `m` at `a`, axis `s` at `c*W+w`, and each other axis at the corresponding unchanged coordinate. The original transpose followed by the inverse inner reshape reconstructs those same coordinates. This uses reshape's preservation of packed position, the permutation's inverse laws, the checked split-product equality, and the already reviewed quotient/remainder selection. It does not require the outer shape to be this intermediate shape: both graphs first reshape the same output index by the same linear position. The outline is mathematical reasoning, not an established Lean proof. When any required extent is zero, no full index exists, so the pointwise obligation is empty; no division by zero is needed on an admitted coordinate.

## Reuse and new step

`LinearIndexLemmas` provides both inverse laws; `IndexTransportAttempt.reshape_linear_value`, `transpose_coordinate_value`, and `replacement_read` already expose the relevant graph coordinates. `CoordinateChunkAdapter.select_coordinate` supplies actual chunk selection, and `OrderedSlices.segment_quotient_remainder` supplies quotient/remainder for bounded local coordinates. These are outside or adjacent to the frozen baseline as documented in the preceding checkpoint; none is a theorem of the desired rewrite.

`ProductAssociation.join_associate` now proves the generic packed-coordinate reassociation across the necessary dependent `Fin.cast`. It has axiom `propext`; accompanying zero-factor impossibility lemmas have no axioms. Tests cover first, interior, last and singleton coordinates, all three zero factors, and an incorrect factor-order control. It uses only frozen `FiniteProduct` and does not alter the generic project library.

The remaining concrete obstacle is lifting that local reassociation through an arbitrary-length prefix and suffix and relating the plan-defined permutation/shape functions and dependent frame casts to the decomposition above. The local theorem alone does not establish that structural bridge, and no target equality is assumed. No general proof was attempted under a new guard or fixed rank. An independent review is still required for any completed proof.

## Adversarial checks and effort

`check-index-samples.py` independently implements the stated integer-coordinate outline with deterministic seed 20261117: among 4,000 generated candidates, 833 failed the frozen outer-element-count premise, leaving 3,167 plans at ranks 2–6. Of these, 2,600 have no output coordinates and 567 are nonempty; 5,909 nonempty coordinates were compared with zero mismatches. The set includes 780 one-chunk plans (276 nonempty), 957 zero-width plans, both zero and positive moved-axis positions, and 1,570 plans with greater outer rank. These tests are a separately written executable model, not Lean checking of each `Conditions` witness or evidence of source correspondence, and empty cases supply no pointwise comparisons.

A fresh Lean 4.35.0 offline replay built the three prerequisite/test modules from scratch, ran the samples, checked all 28 frozen hashes, and passed in 1.03 seconds; details and file hashes are in `product-association-replay.json`. The first candidate compile succeeded with an unused simp-argument warning; removing that argument produced the clean replay. Focused inspection, challenge, proof and validation ran approximately 05:34:30–05:35:59 UTC (89 seconds), separate from prior attempts and review.
