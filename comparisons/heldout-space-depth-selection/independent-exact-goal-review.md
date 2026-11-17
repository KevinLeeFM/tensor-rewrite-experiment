# Independent preproof review: exact space-depth candidate

**Decision: ACCEPTED FOR A BOUNDED REWRITE-PROOF ATTEMPT, as the frozen mathematical model only.** This accepts the exact candidate proposition and its reviewed import closure as a proof target. It does not validate C++ correspondence, source admission/reachability, full branch coverage, novelty, performance, or any rewrite theorem. No target proof exists and none was reviewed.

## Review record

- Repository: `/workspace/tensor-heldout-chunk-20261117`
- Reviewed commit: `1dba7c7fcfb3268e71c0dc05d6a61cc76220762c`
- Review window: 2026-11-17 05:16:00 UTC to 2026-11-17 05:16:44 UTC for final review synthesis and report writing. The earlier file/source inspection start was not instrumented, so total inspection-plus-replay review duration is unavailable.
- Fresh offline replay: 9.080 seconds as measured by `replay_goal.py` (9.165 seconds wall including the Python wrapper); 25 module/control checks passed. The replay ran in `/tmp/independent-goal-review-4wf4oot8`, not in the tracked checkout. It accepted 23 positive checks and observed the two expected adversarial failures. The final printed controls were `CANDIDATE_BASELINE_LEAK` and `CANDIDATE_SIGNATURE_MISMATCH` as expected.
- All 28 entries in `goal-freeze.json` were independently SHA256-checked against disk and matched. The tracked worktree remained clean; no tracked replay record was changed. The source pin in the manifest is `e58e523b11f1fde802a493a776d158007486e1bf`.

## Statement and source interpretation

`GoalCandidate.Goal` is an elaborated universal proposition over arbitrary input rank, outer rank, shapes, a value type and tensor, and a `Conditions` witness. `original` is built from the existing logical `reshapeTensor`, `Tensor.transpose`, and `reshapeTensor`; `replacement` is built from source-frame casts, ordered chunk slices, modeled concatenation, and the actual logical reshape. Neither side is defined using the other's coordinate map, and no final equality is assumed. The output count for the replacement is derived by `chunk_count`; the slice/concat frame shape is derived by `chunk_shape`.

The conditions track the source's first differing split axis, prefix/suffix dimension checks, split product, count cap, selected moved axis, exact offset permutation relation, outer-dimension check precedence, and the original graph's reshape count equalities. The selected permutation axis is well-typed over rank `n+1`; injectivity plus the offset conditions establishes it lies before the split and hence is a legal input-rank concat axis. The source's integer offset arithmetic is represented with Nat subtraction only under that derived ordering, where the subtraction is defined. The `count > 0` fact is derived from mismatch and product; there is no blanket positive-extent premise.

The correspondence with the pinned source block at `algebraic_simplifier.cc:10589–10740` is faithful at the level claimed: split discovery stops at the first differing dimension; later inner dimensions are shifted by one; `num_chunks ≤ 5`; the moved axis avoids the split and adjacent width axis; remaining transpose entries follow the source offset loop; output checks test `transpose_dim - 1` before the split division; chunk slices use `[i*width, i*width+width)` with unit strides, are appended in increasing `i`, and concatenated on `transpose_dim`. The original graph and the replacement reshape have equal logical element counts under the stated premises. `Frame` models logical row-major values, not physical layout.

**Rank boundary:** `outerRankAtLeast` (`input rank ≤ outer rank`) is correctly present and explicitly described as a **model restriction**, not a source guard or established HLO invariant. The C++ loop indexes the outer dimensions for every input axis without a visible outer-rank check; this model excludes the undersized-rank/unchecked-index case. The draft and handoff disclose this accurately. Do not broaden the proof's result to the whole source branch or call this rank condition a source precondition without separate evidence.

Other exclusions are also clear: mathematical `Nat` dimensions do not establish signed-int64 representability or overflow behavior; source slice/reshape/transpose semantics are adopted as interpretation assumptions; layout sensitivity, HLO attributes, visitor ordering, one-user and option checks, side effects, graph mutation behavior, and reachability are not modeled. These limits are appropriate for this goal and are not hidden in theorem premises.

## Generic closure, contamination, and axioms

I inspected the 28 hashed files, their imports, and the relevant model definitions. The dependency direction is generic tensor/index/reshape/concatenation semantics → generic shape, slice transport, ordered block, interval, source-frame, and count lemmas → the candidate definition. The support modules do not state or use the target final equality. The target-specific file introduces `Conditions`, constructs both terms, and defines `Goal`; it supplies no proof. I found no `sorry`, `admit`, `native_decide`, or project axiom in the candidate or generic count proof. `ElementCount.permute_count` uses only Lean foundation axioms (`propext`, `Classical.choice`, `Quot.sound`); replay's audited count declarations stayed within the allowed set. This is not a claim that every imported library declaration is axiom-free.

The operational guard checks the existing 835-name fixed-tactics proof inventory, and its negative import is rejected. The wrong-signature control is well typed and is rejected with the expected signature mismatch. This is a known-inventory and wiring check, not a universal adversarial-code sandbox. For the eventual proof, run `GoalCandidateGuard.exactGoal` on the actual elaborated theorem against `Heldout.SpaceDepthCandidate.Goal`; do not rely on the guard's mere presence. Then audit that theorem's axiom dependencies and check for proof contamination again.

## Cases and controls

The accepted generic lemmas quantify arbitrary finite ranks, including rank zero where applicable, and avoid cancellation in zero cases. Tests cover scalar empty-product count, zero extents on split and untouched axes, zero factor/count, width-zero repeated interval starts, one chunk, no intervals, interval bounds, split/permutation failures, and a zero-domain goal example. The nonempty plan evaluates both original and replacement at a concrete coordinate to `3`; the wrong-axis construction is well typed and returns `24` against the original's `3` at the selected flattened position. These examples establish that the model and controls are not wholly vacuous, but finite examples do not prove the candidate or native source behavior. The invalid examples are local arithmetic/guard controls, not an exhaustive native admission test.

## Proof gate

Proceed only with a proof whose elaborated type is exactly `Heldout.SpaceDepthCandidate.Goal`, under the frozen hashes. Keep the rank restriction and all external assumptions visible in the result. A proof will establish this mathematical tensor equality, not the C++–Lean correspondence or global optimizer correctness. Preserve this review and freeze; if the proposition or any imported hash changes, request review of the changed exact statement/closure before treating this acceptance as applicable.
