Setup and source inspection began 23:56:56 UTC Nov 17. Freeze b73a860 (see Git author/committer timestamps), Lean 4.35.0. Compiling inherited Tensor took 0.360 s; elaborating the pre-proof case took 0.365 s. One exploratory name lookup reported an absent unused list lemma. Development first failed in 0.564 s: rewriting cyclic_val without explicit arguments rewrote the outer cast, and unfolding canonicalEntry under filterMap hid the induction-hypothesis form. Specifying the inner arguments and splitting only the head's retained flag repaired both. Next proof compiled with deprecation/unused-simp warnings in 0.436 s. Clean proof 0.419 s and controls 0.332 s. Fresh author replay times and axiom report are in author-replay.log. Wall times overlap worker thought/coordination and include harness setup. Compiler list excludes untimed name lookups. Independent review separate; tokens and active reasoning unavailable. No dependency setup, downloads, or broad replay.
Tue Nov 17 23:59:59 UTC 2026
  32 comparisons/revised-benchmark-20261117/rotation-model/RotationControls.lean
  92 comparisons/revised-benchmark-20261117/rotation-model/RotationProof.lean
  65 comparisons/revised-benchmark-20261117/rotation-model/RotationSpec.lean
  36 TensorRewrite/Pilot/Tensor.lean
 225 total
