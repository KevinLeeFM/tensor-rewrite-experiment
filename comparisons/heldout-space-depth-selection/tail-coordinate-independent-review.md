# Independent review of tail-coordinate theorem

A fresh gpt-6-luna reviewer, with no further agents or edits, reviewed commit `2d674f4bb64566ce213f2214aabf3219595a02b4`. Verdict: accept `actual_tail_packed_values_equal` as a supporting result only, not the rewrite.

The reviewer checked the actual statement, frozen goal, assumptions and transitive project closure. The result equates natural packed positions of the original and replacement tails for any valid plan, input and output index. Its dependencies do not assume the target index equality or tensor rewrite. Both manifests matched (28 original inputs, 45 separate recursive-closure inputs); the outer-rank premise remains a disclosed model restriction, not a verified source invariant.

Fresh offline Lean 4.35.0 replay in a temporary copy passed all 38 compile/control steps in 12.625 seconds, with no warnings or `sorryAx`. The theorem reports only `propext`, `Classical.choice`, and `Quot.sound`; the reviewer found no `sorry`, `admit`, `native_decide`, or added project axioms in the checked candidate/helper modules. Nonempty pointwise, one-chunk, empty-input and zero-width controls passed, with no output indices in the empty and zero-width fixtures. Review took approximately five minutes.

The still-open merged-head relation requires identifying the actual two original prefix-axis coordinates with the single merged replacement coordinate using the common suffix and dependent rank/index casts, then connecting quotient/remainder to chunk selection. Neither this review nor the packed-tail theorem proves that equation, the exact rewrite, C++ correspondence, or a speedup.
