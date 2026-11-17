# Suffix-coordinate gate: independent review and full-index residual

**Accepted component; full input-index and original rewrite unresolved.** At proof checkpoint `525392125a`, a fresh Luna reviewer independently accepted `Heldout.ActualSuffixProof.Goal_proved : Heldout.ActualSuffixGoal.Goal` against the exact goal frozen at `05f23ca`. The reviewer inspected the target, proof, actual-tail packing and suffix lemmas, `Conditions`, existing controls, failed full-index residual and 47-input closure. All 47 frozen hashes matched, as did the previously verified original and recursive manifests. No proof bypass, circular desired equality, or added assumptions were found. Permitted axioms were exactly `propext`, `Classical.choice`, `Quot.sound`. The `outerRankAtLeast` assumption remains a **model restriction**, not a source invariant; no C++ correspondence is asserted.

The conclusion compares every suffix coordinate of the actual two frames after dropping the left two-axis head and right one-axis head. It follows from packed-tail equality, matching head and suffix counts, then equality of suffix packed components and linearize/delinearize transport. It does not connect those coordinates to the input index. `nonemptyPlan` has rank 3 and moved axis 1, so `k = 1`, and the reviewer instantiated the theorem on that plan and an admitted output. Suffix-rank-zero or empty-output domains are vacuous. Existing one-chunk and zero-width controls were retained. The existing wrong-axis negative discriminates the broader source-shaped replacement, not a direct mutation of this suffix equation.

## Replay and review

Using fresh temporary `LEAN_PATH` and pinned Lean 4.35.0, the reviewer compiled the 42-module local closure, including the accepted merged-head goal/proof and current suffix goal/proof, without warnings or `sorryAx`. It used the explicit `replay_tail_coordinate.py` list, followed by `MergedHeadConnection`, `ActualMergedGoal`, `ActualMergedProof`, `ActualSuffixGoal`, and `ActualSuffixProof`, each with `lean "$source" -o "$temp/$module.olean"`. A corrected full replay with controls and concrete theorem instantiation passed in 16.482 s. An initial approximately 17.1 s control replay failed because the existing test namespace was not accessible from a separately generated module; compiling controls in the same Lean source repaired the test harness. Independent review observed 17:24:03–17:27:27 UTC (3m24s elapsed), inclusive of replay; reviewer active time is not separately known.

Frozen suffix goal SHA-256 `1b86c29d238434cb445566794bf2f123f3db6b6b0f227571c0b78ba3167e31db`; suffix proof `ea41cf5fcf23053e788fa8ccb91eee68ac940383943d9307898e2d16325daf92`; full-index goal `3b64a66fabba9627db2de5a77d9f0fbaaa30b2830ffed2b969cc763e10976a2b`; manifest `1564a9d438ad88c257314f313d0450bb95a7b5d01fe1c932bc816d2320ea40b0`. The accepted merged-head proof and both original freezes are unchanged.

## Full-index attempt and next missing link

The worker immediately attempted the unchanged `Heldout.ActualFullIndexGoal.Goal`, which states `originalIndex plan out = replacementIndex plan input out` under the same Conditions. The direct `funext`/unfold reduction left the complete per-axis original reshape–transpose–reshape versus replacement `sourceIndex` equality; see `ActualFullIndexProof.lean.txt` and `actual-full-index-residual.log.txt`. The failed compilation reports `sorryAx` because Lean leaves the unsolved theorem body incomplete; this is not accepted proof evidence. The missing source-specific step is to relate the original split-axis coordinates to chunk row and local width column, while connecting the remaining coordinates through the actual permutation and dependent frame casts. No smaller complete bridge was established. A future attempt should state and justify that exact link before coding, preserve both component proofs, and return to the original index equation; a generic helper alone would not close it. Cost is unknown.

## Time and failed attempts

Coordinator setup started 17:15:35 UTC; target commits were ready at 17:16:36. Setup compiled the suffix goal in 0.563 s and full-index goal in 0.411 s; a preceding wrapper failed before Lean because `/usr/bin/time` was unavailable. The scoped worker was dispatched after 17:16:36 and its last recorded compiler result was 17:21:20, approximately 4m44s wall time, not measured active time. All worker invocations used pinned Lean with `/tmp/space-merged-gate-20261117`:

| UTC start–end | Seconds | Outcome |
|---|---:|---|
| 17:18:13 | unknown | Wrapper failed before Lean (`/usr/bin/time` absent). |
| 17:18:21.284–21.464 | 0.180 | Suffix draft: missing temporary `ActualMergedProof.olean`. |
| 17:18:39.824–40.277 | 0.453 | Merged goal passed. |
| 17:18:40.277–40.874 | 0.596 | Merged proof passed. |
| 17:18:40.874–41.261 | 0.387 | Suffix goal passed. |
| 17:18:50.992–51.581 | 0.589 | Suffix draft: `tail_axis` rewrite mismatch. |
| 17:19:58.431–59.075 | 0.644 | Suffix draft: dependent cast normalization failed. |
| 17:20:32.602–33.246 | 0.644 | Suffix draft: `suffix_extents` namespace not open. |
| 17:20:45.258–45.898 | 0.640 | Exact suffix theorem passed. |
| 17:21:19.176–19.624 | 0.447 | IndexTransportAttempt passed. |
| 17:21:19.624–19.968 | 0.343 | Full-index goal passed. |
| 17:21:19.968–20.315 | 0.347 | Full-index proof failed on saved per-axis goal. |

No blocked external access, downloads, broad builds or unrelated proof campaign occurred. End-to-end active time, individual review-module compilation times and token costs are unknown; recorded intervals must not be summed as if nonoverlapping. No speedup claim is supported.
