# Row-major split and split-axis: independent review

**Accepted: row-major decomposition, actual split factor and split-axis equality.** At proof commit `99aa54a5a75f476fbdfa179991cfed4c1dae56aa`, `Heldout.RowMajorSplitProof.target_attempt` proves the exact frozen `Heldout.SplitStrategyTarget.Goal`, `Heldout.RowMajorSplitIntegration.factor` proves `Heldout.ActualSplitFactorGoal.Goal`, and `Heldout.RowMajorSplitIntegration.split` proves `Heldout.RemainingAxisGoals.Split`. The proof obtains the actual packed prefix/tail relation from plan extents/counts and reshape positions, applies a local row-major component lemma, then uses accepted transport and suffix results for the selected row and width coordinate. The split proof consumes the factor and source interval/frame relation. No added assumption or circular use of the target was identified.

**Whole rewrite remains unproved.** The accepted moved and split axes leave `Heldout.RemainingAxisGoals.Other`, full input-index equality and frozen `Heldout.SpaceDepthCandidate.Goal`. The outer-rank restriction remains an explicit model restriction rather than a source invariant. Empty output-index domains are vacuous. No C++–Lean correspondence or speedup claim follows.

## Independent review and controls

A fresh independent reviewer inspected the exact statements, proof/import closure and assumptions, and replayed the recursively derived 54-module local closure with an initially empty temporary `LEAN_PATH` under Lean 4.35.0 commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. All commands passed without warnings in 22.13 s. The target, factor and split theorems report only `propext`, `Classical.choice`, `Quot.sound`; a closure source scan found no `sorry`, `admit`, `native_decide`, or new axiom declarations. The toolchain and standard library were reused, not rebuilt.

The 70-input row-major freeze, 28-input original goal, 45-input recursive and 77-input prior split freezes all matched. Controls include an admitted nonempty plan with count 2 and width 3 and actual chunk position 3→4 boundary, plus an empty output-domain uninhabitability check. Existing wrong-axis control distinguishes concrete graph reads but is not a direct negative mutation of these universal theorems. Historical failed drafts remained quarantined `.lean.txt`/logs and outside the accepted proof closure.

Target SHA-256 `340a0a2290c5678279ec35b39dd6fc537336762ac36061212a947cd559dd535b`; proof `d2797ca698b5d1b5121a51c137a734187a1e8db8745cd01567f30b43dcee0372`; integration `e08002e08485fc30f444e0ff34d2460d79ca10caf376ec8f5c7f086c09af5fb1`; freeze `f3609e4b0d66d2f475e10ec24e1002c639d9222a3e4e1de526feda737d620b90`.

## Timing and failures

Setup started 2026-11-17 19:34:52 UTC; the 70-input freeze was committed at 19:35:27. Observed worker window was approximately 19:35:55–19:43:50 (7m55s). The independent review ran 19:44:52–19:46:10 (1m18s), including the 22.13 s replay. Active reasoning and token costs were not measured. At the 10-minute gate the exact split had compiled and only independent acceptance remained. No broad build or download occurred.

Worker compiler ledger, UTC start–end, duration/return code:

| Start–end | Seconds / rc | Result |
|---|---:|---|
| 19:36:38.571–38.726 | .155 / 1 | Missing target olean. |
| 19:36:43.356–43.690 | .334 / 0 | Target dependency. |
| 19:36:48.510–48.838 | .329 / 0 | Local merged-head component. |
| 19:37:29.360–29.887 | .528 / 1 | Initial actual-plan application. |
| 19:37:51.044–51.710 | .666 / 1 | Actual-plan application. |
| 19:38:23.883–24.798 | .915 / 1 | Prefix/tail exploration. |
| 19:38:36.108–36.936 | .828 / 1 | Prefix/tail exploration. |
| 19:38:44.660–45.418 | .758 / 1 | Prefix/tail exploration. |
| 19:38:53.691–54.457 | .766 / 1 | Actual-prefix/tail exploration; temporary `fail` removed. |
| 19:39:09.396–10.260 | .864 / 0 | Exact frozen row-major target. |
| 19:39:47.725–48.685 | .959 / 0 | Proof olean. |
| 19:40:06.059–06.586 | .527 / 1 | Row proof cleanup. |
| 19:40:13.573–14.090 | .517 / 0 | Actual selected row. |
| 19:40:41.797–42.401 | .604 / 0 | Actual local width. |
| 19:41:00.447–01.158 | .712 / 1 | Factor let/frame transparency. |
| 19:41:16.569–17.245 | .676 / 1 | Integration normalization. |
| 19:41:29.166–29.813 | .647 / 1 | Integration normalization. |
| 19:41:37.320–38.016 | .697 / 1 | Split frame/cast. |
| 19:41:51.645–52.311 | .666 / 1 | Split frame/cast. |
| 19:42:00.538–01.193 | .655 / 1 | Split frame/cast. |
| 19:42:10.088–10.714 | .627 / 1 | Split frame/cast. |
| 19:42:29.834–30.534 | .700 / 1 | Split frame/cast. |
| 19:42:41.592–42.293 | .702 / 1 | Split frame/cast. |
| 19:42:54.395–55.068 | .673 / 0 | Exact split theorem. |
| 19:43:17.745–18.366 | .621 / 0 | Existing controls. |
| 19:43:24.137–24.802 | .665 / 0 | Integration olean. |
| 19:43:30.547–31.157 | .610 / 0 | Controls olean. |
| 19:43:39.083–40.294 | 1.211 / 1 | Private control declarations inaccessible as separate import. |
| 19:43:49.322–50.021 | .699 / 0 | Same-source boundary theorem instances. |

Failed elaborations sometimes print `sorryAx` from incomplete proof state; none are accepted proof evidence. The final sources and fresh replay contain no such bypass. Prior prohibited temporary scaffold remains documented in its historical review and was not imported.
