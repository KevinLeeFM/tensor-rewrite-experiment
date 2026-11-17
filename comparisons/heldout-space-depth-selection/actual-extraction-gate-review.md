# Moved coordinate extraction: partial independent review

**Accepted replacement-side extraction; moved-axis and rewrite unresolved.** `Heldout.ActualMovedExtractionProof.ReplacementGoal_proved` proves the exact frozen `ReplacementGoal`: at the moved/concatenation source axis, the actual replacement input coordinate equals the successor coordinate of the original outer index. It consumes the independently accepted merged-position theorem and `selected_chunk_coordinate` to recover the local column. Its dependencies are noncircular. The independent reviewer accepts this component, not the original-side `Goal`, the complete moved-axis equality, split axis, full-index equality or original space-depth rewrite.

`Heldout.ActualMovedExtractionIntegration.moved_axis_equality_of_original_extraction` compiles but explicitly assumes the still-unproved original-side `Goal`. It shows that proving that precise premise would combine with the accepted replacement result to close the moved-axis case. The exact original-side diagnostic is preserved as `actual-original-extraction-residual.log.txt`: it equates the original `delinearize`/`linearize`/transpose coordinate at `concatAxis` to `originalOuterIndex` at moved+1. Existing packed-position preservation does not by itself extract the coordinate. No direct existing axis-extraction lemma was found. A future proof needs a justified relation between coordinates of the two delinearizations and their suffix products; no such relation is proved here. No split-axis attempt was made.

The outer-rank condition remains a model restriction, not a source invariant. Empty and zero-width output-index cases are vacuous; no C++–Lean correspondence or speedup is claimed. The previous transport direct-instance namespace failure remains documented in `actual-transport-gate-review.md`; its raw temporary output was not retained. This pass repaired the harness by compiling `ActualTransportInstanceControl.lean` in the same source as the existing tests. It passed on the nonempty plan with no changed assumptions, using the existing local compiled closure; the independent fresh replay below rechecked it.

## Independent verification

A fresh Luna reviewer inspected the exact goals, proof, conditional reduction, prior failure, accepted transport and selector, and the 63-input closure. All 63 hashes and the earlier 28-, 45-, 43-, 47-, 56- and 52-input freezes matched. A fresh offline Lean 4.35.0 replay compiled 50 source modules plus a generated concrete control in 19.039 s with no warning or `sorryAx` failure. Both the replacement proof and conditional reduction use exactly the allowed axioms `propext`, `Classical.choice`, `Quot.sound`. A concrete nonempty replacement extraction instance compiled. Existing controls cover one-chunk, empty/zero-width boundary cases, and the wrong-concatenation-axis graph output; that wrong-axis control is not a direct mutation of this extraction equation.

The reviewer's first runner omitted `MergedHeadConnection` and failed after approximately 14 s; the ephemeral module list was corrected. A separate concrete-control attempt failed on an unqualified namespace and was corrected before the final replay. These are validation overhead, not mathematical failures. Review elapsed 18:23:28–18:27:29 UTC (4m01s), including replay; active review time is unknown. The proof SHA-256 is `fbb7bdf4ff652afaa27bd6176e3536ad79760f76c1177d57caddc6fd823a558d`; goal `0f574ea41431c93e32393f59604bf7720175caa267262b39aaf4d87ed376e360`; integration `b42047bd07240fdcc89d8fae6629a251024f5d4c39927df5a78f5f6cc427d9c3`; freeze `3224d31f164591049949b4a9c739a088bea5a6833c0b94a70161c26eebc985e3`.

## Timing and failures

Setup began 2026-11-17 18:09:07 UTC. Repaired transport instance compiled at 18:09:24 in 0.541 s; the initial and final extraction specifications elaborated in 0.433 s and 0.376 s respectively; frozen commit was made at 18:10:24. The worker was dispatched thereafter; its last compile completed at 18:21:45.733. Active reasoning and token usage were not instrumented. Compiler invocations below used pinned Lean and the local prebuilt closure; failures are preserved as reported by the worker, and the exact original residual was saved.

| UTC start–end | Seconds | Result |
|---|---:|---|
| 18:13:50.517–51.145 | 0.628 | Failed: replacement coordinate residual. |
| 18:14:35.781–36.405 | 0.623 | Failed: permutation/shape bounds. |
| 18:15:36.549–37.212 | 0.663 | Failed: column/coordinate reductions. |
| 18:16:32.387–33.035 | 0.649 | Failed: cast and namespace. |
| 18:16:47.065–47.671 | 0.605 | Failed: coordinate cast mismatch. |
| 18:17:03.971–04.578 | 0.606 | Failed: frame-axis cast mismatch. |
| 18:17:17.629–18.254 | 0.625 | Failed: frame-axis cast mismatch. |
| 18:17:38.266–38.888 | 0.621 | Failed: cast value mismatch. |
| 18:17:50.301–50.887 | 0.586 | Failed: cast value mismatch. |
| 18:18:15.563–16.179 | 0.616 | Failed: dependent cast goal. |
| 18:18:47.319–47.985 | 0.666 | Passed replacement extraction. |
| 18:19:36.882–37.435 | 0.553 | Failed: ambiguous `Goal` name. |
| 18:19:54.075–54.668 | 0.593 | Failed: original-coordinate residual. |
| 18:21:31.892–32.446 | 0.555 | Passed clean replacement replay. |
| 18:21:32.450–32.742 | 0.292 | Failed: `concatAxis` namespace. |
| 18:21:45.361–45.733 | 0.371 | Passed conditional integration. |

The 10-minute supervision gate found a compiled replacement extraction and permitted the immediate direct attempt on its original-side complement. At the concrete delinearize obstacle proof search stopped; independent review followed sequentially. No broad build, download, extra worker or primary merge occurred. Individual timing intervals overlap only where stated and are not a sum of worker labor.
