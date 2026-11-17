# Independent review of bounded proof attempt

Reviewer: fresh gpt-6-luna agent; no further agents or edits. Review time: approximately 3 minutes, separate from the 123.5086-second proof-development phase. The review is of an incomplete attempt and does not accept the rewrite.

All 28 frozen input hashes matched. The local `delinearize_linearize` lemma compiled offline with Lean 4.35.0 using the existing `ordered-build` import artifacts; its reported axioms are `propext`, `Classical.choice`, and `Quot.sound`. The first review replay attempted the absent `.lake/build/lib` path and failed; the following command succeeded:

```sh
LEAN_PATH=comparisons/heldout-space-depth-selection/ordered-build \
  /workspace/toolchains/lean-4.35.0-linux/bin/lean \
  -o /tmp/SpaceDepthProof-review.olean \
  comparisons/heldout-space-depth-selection/SpaceDepthProof.lean
```

This inverse lemma already exists in `TensorRewrite/Pilot/LinearIndexLemmas.lean`, which is outside the frozen closure. It is not novel library evidence, and importing the existing theorem would change the frozen closure.

The reviewer found the recorded obstacle concrete: the frozen helpers separately establish chunk selection and source-axis values, but do not connect the reshape/transpose source index to concatenation's output index and frame casts. That transport and the quotient/remainder relation remain to be proved. The local inverse lemma does not prove the rewrite. The reviewer did not independently rerun the full controls.

The coordinator separately replayed the frozen goal and controls from an isolated copy: 25 checks passed in 9.03 seconds; details are in `proof-attempt-controls.json`. The nonempty example gives 3 on each side; the well-typed wrong-axis result gives 24 and differs. Contamination and wrong-signature controls failed as expected. These are controls on the specification, not a proof of the general goal.

The `outerRankAtLeast` guard remains a model restriction, not an established source invariant. No C++–Lean correspondence or speedup is claimed.
