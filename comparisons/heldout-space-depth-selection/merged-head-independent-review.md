# Independent review of conditional merged-head helper

Fresh gpt-6-luna reviewer, no further agents or edits; reviewed commit `ba77199f41fc6d12a238deac4245c23f219323be`. Verdict: accept the conditional generic helper, not its unproved actual-plan premises and not the rewrite.

The theorem derives the one-axis merged-head coordinate from equality of whole packed positions and of head and suffix counts. Its existing generic split and component-injectivity imports contain no desired-goal assumption or circular dependency. The helper hash is `54e7e5554cb77dc71340a215fbfddbeaa42855c73b6335fe2c12d54d1dc644b4`. Both original and recursive-closure freezes matched all 28 and 45 recorded inputs.

A fresh offline temporary-copy Lean 4.35.0 replay compiled the prerequisite closure, helper, existing controls and an additional zero-suffix-rank control in 13.565 seconds. Reported theorem axioms were `propext`, `Classical.choice`, and `Quot.sound`; no `sorryAx` or warnings. Controls covered nonempty, wrong packed position, zero-extent index impossibility and the rank-zero suffix. Initial reviewer control elaboration failed because a dependent bound did not unfold its shape; correcting the temporary control resolved it. Review including replay took approximately six minutes; no checkout files were changed by the reviewer.

The remaining actual-plan work is to transport both tail shapes and indices across the `k+2`/`k+1` rank casts, derive the head count from `tail_extents_merge`, derive the suffix count from `WorkerSuffix.suffix_extents`, and carry `actual_tail_packed_values_equal` through those casts. No source correspondence, full rewrite proof or speedup is claimed; the outer-rank condition remains a model restriction.
