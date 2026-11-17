# Split factorization: bounded unresolved attempt

**Unresolved.** The frozen `Heldout.ActualSplitFactorGoal.Goal` states that the original input's split-axis coordinate equals the actual selected chunk row times width plus the actual replacement outer-frame split coordinate. Neither this factorization nor `RemainingAxisGoals.Split` was proved. The saved no-sorry draft and diagnostic are `ActualSplitFactorProof.lean.txt` and `split-factor-attempt-diagnostic.log.txt`; no integration theorem was created. Other axes, full-index equality and the original space-depth rewrite remain open.

A separate Luna reviewer inspected the frozen target, source-index/frame/interval definitions and accepted supporting results. The factor equation is a sufficient mathematical bridge to the frozen split case once a short replacement-coordinate identity is proved: `sourceIndex_split_value` gives interval start plus local split coordinate; interval start is row times width; `concat_distinct`, `Frame.withPosition`/`rest` and value-preserving casts identify the local coordinate with the one on the factor's RHS. This adapter has **not** been compiled. The same actual row occurs on both sides, so no separate row-to-original equality is needed for this implication, although a row relation is needed to prove the factor itself. All 77 frozen input hashes and the reviewed prior freezes matched. The review was source/evidence inspection; it ran no Lean replay and did not accept a proof.

A proposed concrete counterexample was incorrect: Lean rejected the draft's asserted inequality because `decide` determined it false for the valid plan. This single matching instance is neither a general proof nor a counterexample. The worker initially predicted the original coordinate incorrectly; Lean's reduction corrected it to 1. The final saved draft has no `sorry`, but remains intentionally uncompilable because it asserts that false inequality. An earlier exploratory goal-printing scaffold briefly used a prohibited `sorry` and compiled; it was removed on instruction and is not proof evidence. No new assumptions or axioms were accepted.

A different candidate route is a target-local row-major decomposition at the adjacent count/width axes using existing recursive shape/index split and `delinearize_linearize` facts. It must then use accepted transport/chunk-selection for the actual row and accepted suffix transport for the local width, and immediately compile the exact factor and `Split`. No such decomposition was proved here, and its cost is unknown. The outer-rank restriction remains a model restriction; empty output domains are vacuous. No C++–Lean correspondence or speedup is claimed.

Frozen target SHA-256 `8d8b884342a1d812a1179ef4614a322ecc8f22e2c394e20bfd66444c85c04277`; manifest `0e8cf53e59839982305abd7b0053d20e1e866c6f02b1de597b9e71242f12ae91`; saved failed draft `427fcc471bf0144ae1bd00da5a074486b5df491e52ed0672f55cad4ec0dd807f`. Original and accepted prior frozen sources were unchanged.

## Timings and failures

Setup started 2026-11-17 19:09:21 UTC; the exact target elaborated in 0.791 s at 19:09:42 and the freeze was committed 19:10:01. The worker stopped after the last compiler result at 19:20:39, about 11m18s from setup, because the concrete witness matched and no split-coordinate proof had compiled. Command results below are worker-reported wall times. Reviewer elapsed was roughly three minutes, with exact start/active time uninstrumented. The 20-minute gate retained only the requested bounded independent review. Token cost and active reasoning time are unknown.

| UTC start–end | Seconds | Outcome |
|---|---:|---|
| 19:12:12.637–12.803 | 0.166 | Missing LEAN_PATH; module lookup failure. |
| 19:12:19.155–19.599 | 0.444 | Goal-print scaffold rc 0 with prohibited temporary `sorry`; removed, not evidence. |
| 19:12:54.592–55.037 | 0.445 | No-sorry scaffold rc 1, original factor residual. |
| 19:16:18.950–19.395 | 0.445 | Witness draft, unavailable tactics. |
| 19:16:46.352–46.801 | 0.449 | `Std.Tactic` did not supply tactics. |
| 19:17:10.712–11.188 | 0.476 | Witness fields elaborated; invalid reduction names. |
| 19:17:54.095–54.567 | 0.472 | Broad simplification left large expression. |
| 19:18:53.346–54.191 | 0.845 | Reduction harness syntax error. |
| 19:19:23.189–24.056 | 0.867 | Unmatched parentheses. |
| 19:19:45.762–46.576 | 0.814 | Wrong namespace. |
| 19:20:32.852–33.355 | 0.503 | Wrong namespace in direct check. |
| 19:20:38.929–39.408 | 0.479 | `decide` rejected proposed inequality; witness matches. |

A coordinator rerun at 19:22:38 returned rc 1 in approximately 0.493 s and preserved the final diagnostic. No broad build, download, primary merge or new campaign occurred.
