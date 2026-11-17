# Independent review of tail-count integration

Fresh gpt-6-luna reviewer, no further agents or source edits; reviewed commit `8c72c978ea07947aa3658695bdfa0525dd13c3ea`. Verdict: accept `TailCountIntegration.lean` as a support lemma; it does not prove the frozen rewrite.

`plan_tail_count` derives actual equal tail element counts from the merged head extent and pointwise suffix extents. The replacement shape is independent of input tensor values, justifying its use of the suffix theorem's constant input. The derived prefix packed-coordinate equality has no extra tail-count assumption. The reviewer found no circularity, hidden target equality, changed model condition or new axiom. The outer-rank condition remains a model restriction, not a source guard.

All 28 original and 45 separate-freeze input hashes matched. Fresh offline replay from a temporary archive rebuilt 36 modules and controls in 12.263 seconds on Lean 4.35.0. Printed axioms were limited to `propext`, `Classical.choice`, and `Quot.sound`, with no warnings or `sorryAx`. Nonempty, one-chunk, zero-extent and zero-width controls were replayed; empty domains do not contain valid output indices. Review and replay took approximately two minutes.

The reviewer identified the next bridge: recover equality of actual tail packed coordinates and then prove the replacement merged coordinate equals the original count coordinate times the moved extent plus the original moved coordinate, connected to actual chunk selection, permutation and dependent casts. These statements and the exact rewrite were not proved by this review.
