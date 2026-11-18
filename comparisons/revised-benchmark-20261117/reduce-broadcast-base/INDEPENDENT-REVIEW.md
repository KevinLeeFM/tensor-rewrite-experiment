# Independent review: reduce over mapped broadcast axes

**Verdict: the frozen broad client-level model is refuted, but this is not a
counterexample to the verified-HLO benchmark rewrite.** The plan permits
`inputRows = 1` or `inputRows = outputRows`, matching the relevant
`ShapeInference::InferBroadcastShape` size rule. At `[1,2] → [3,2]`, mapped
dimensions `[0,1]`, reduction over `[0,1]`, and the given exact integer data,
the original counts the row three times while the base-first replacement
counts it once. The control values `(12,-9)` and `(4,-3)` distinguish the
terms. The separate `equalProfile` theorem proves equality when the mapped
row extents are equal.

The source domain needs a verifier correction. The HLO simplifier consumes
`HloInstruction` broadcasts. `ShapeVerifier::HandleBroadcast` at
`sources/xla/xla/service/hlo_verifier.cc:1741–1762` requires every mapped
operand extent to equal its mapped output extent; unlike client-side shape
inference, it does not admit mapped singleton expansion. Thus the `[1,2] →
[3,2]` witness is not a valid verified-HLO input to the benchmark pass. The
current conclusion is therefore: broad client-shape model refuted; valid
equal-mapped-extent model profile proved; no source implementation bug or
whole source record refuted. The packet itself makes the distinction, and
this review narrows source-reachability language accordingly.

This verifier restriction also applies to the unit-axis expansion extension
described in the other worker's `sink-mixed-broadcast/INDEPENDENT-REVIEW.md`:
the expanded-coordinate theorem is a valid mathematical extension, but a
mapped size-one-to-larger HLO broadcast is outside the verified-HLO source
domain. The equal-mapped-extent portion remains the source-relevant scope.
This note does not modify that review.

The model is over exact `Int`; signed zero and NaN are inapplicable. The
Lean counterexample is a model witness only and does not establish a runnable
compiler failure. No diagnostic, failed build, or shape-verifier rejection
is counted as a benchmark refutation. The proof axiom outputs were
`[propext]` for `refuted` and `[propext, Quot.sound]` for `equalProfile`.

Fresh Lean 4.35.0 replay verified all four frozen hashes and compiled
`BaseSpec`, `BaseProof`, and `BaseControls` in 0.387 s, 0.349 s, and 0.298 s
(1.034 s total reported compiler wall). No build, download, or native run was
performed. Independent review time was not separately instrumented.

The source rewrite inspected at `algebraic_simplifier.cc:9443–9492` commutes
reduction over mapped axes that originate in the broadcast base. The shape
verifier condition is material to the applicability domain and must accompany
any source-level case count.
