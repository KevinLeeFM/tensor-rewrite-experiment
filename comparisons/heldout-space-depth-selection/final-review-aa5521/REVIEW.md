# Space-depth full candidate: independent review, policy scope unresolved

**Verdict: REVISE / not accepted.** The exact original frozen mathematical proposition compiles at candidate `aa5521b38e8304a14350a684f9cef914d1f65158`, and the independent reviewer found no hidden target equality or circular assumption. However, the frozen `GoalCandidateGuard.noCampaignProofs` rejects five declarations present in the final environment. Earlier records call it a preproof baseline guard and separately review the generic inverse lemmas, but do not unambiguously adjudicate whether its 835-name prohibition applies to the expanded final proof environment. The reviewer requires that policy boundary be resolved; genericity alone is not a waiver. The actual final-environment guard **failed**. Do not promote this candidate to independently accepted whole-case proof on this evidence.

## Mechanical and source evidence

- Fresh offline Lean 4.35.0 (`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`) replay compiled 58 recursively ordered local modules from an initially empty temporary `LEAN_PATH` in 25.226 s; no warnings or `sorryAx` were reported in successful modules. `replay.log` and the retained `replay.py` list modules and commands. The script's `/tmp/space-depth-independent-aa5521/olean` location was initially empty for that run; a later replay must use a fresh location rather than silently reusing it. The installed toolchain/Std were reused, not independently rebuilt.
- All 12 stored freeze manifests, including the original 28-input goal, 45-input recursive, 70-input row-major, 73-input other-axis and 77-input prior split freeze, matched. `GoalCandidateGuard.exactGoal` passed for `Heldout.OtherAxisIntegration.rewrite` against `Heldout.SpaceDepthCandidate.Goal`; wrong-signature and known-contamination controls failed as expected. `checks.log`, `signature-negative.log`, `leak-negative.log` record actual outputs.
- The other-axis theorem, full-index theorem, and original rewrite report exactly `propext`, `Classical.choice`, `Quot.sound`. No successful theorem used `sorryAx`; successful closure scan found no prohibited executable source tokens or added axiom declarations. Failed worker-elaboration diagnostics are quarantined in `other-axis-worker-diagnostics.log.txt` and are not proof modules.
- Existing nonempty, one-chunk, zero-extent, width-zero, chunk-boundary and wrong-axis controls compile. The wrong-axis control tests concrete graph reads, not a mutation of the universal theorem; empty output domains are vacuous.
- Reviewer inspected all 58 local module bodies in a focused fast source/dependency pass, plus the original frozen statement, conditions, exact signatures and prior review evidence. The moved/split/other partition is exhaustive, and Other covers before-moved, between, and after-split regions. Source-specific helper facts are proved in experiment modules; generic inverse/concatenation modules do not hide the target equality. This fast audit is not a formal verification of Lean's kernel or external Std.

## Guard conflict and exact residual

The actual guard output in `checks.log` rejects `TensorRewrite.Pilot.FiniteProduct.column_join` on its first hit. A separate inventory in `inventory.log` enumerates precisely five names present: `FiniteProduct.column_join`, `FiniteProduct.join_row_column`, `FiniteProduct.row_join`, `LinearIndex.delinearize_linearize`, and `LinearIndex.linearize_delinearize` (all under `TensorRewrite.Pilot`). These are generic row/column and linear-index inverse lemmas, not target rewrite theorems; their inclusion in the frozen fixed-tactics forbidden inventory is nevertheless objective. The final environment is not guard-clean.

The earlier `independent-exact-goal-review.md` described the guard as checking a preproof baseline, and directed the eventual proof to run `exactGoal`, audit axioms and check proof contamination. Later reviewed freezes explicitly included the generic inverse-lemma modules. Those facts support a narrower baseline-only reading but do not by themselves settle whether this final environment is exempt from the original inventory. Independent reviewer verdict is REVISE until the owner adjudicates that specific policy scope (or an otherwise authorized guard-clean proof is supplied), with its consequences for held-out experiment accounting recorded. Do not change the frozen goal, inventory or prior verdict to manufacture a passing guard. If baseline-only scope is confirmed, the final theorem still needs final acceptance recorded against that explicit policy interpretation, not a claim that the guard passed on final imports.

## Timings, attempts and boundaries

Coordinator setup began 2026-11-17 19:48:33 UTC, freeze committed 19:49:10; worker compilation window was 19:50:22–19:53:58. The independent fresh replay was 25.226 s; first review was 19:54:53–19:57:20 and follow-up complete-source pass 19:57:50–19:59:24 (1m34s). These are wall intervals, not separately measured active time. Token costs, active reasoning and any blocked/idle time are unknown. Exact per-command worker ledger follows; failures with incomplete goals sometimes emit `sorryAx` but did not produce accepted proof. The full target was never weakened.

| UTC start–end | Seconds / rc | Result |
|---|---:|---|
| 19:50:22.157–22.802 | .646 / 0 | Initial proof component. |
| 19:50:51.077–51.674 | .596 / 1 | Missing namespace. |
| 19:50:58.319–58.885 | .566 / 1 | Missing Fin bound. |
| 19:51:09.223–09.847 | .624 / 0 | Component. |
| 19:51:30.740–31.456 | .716 / 1 | Replacement cast residual. |
| 19:51:39.126–39.775 | .649 / 1 | Same residual, unused simp warning. |
| 19:51:46.500–47.170 | .671 / 0 | Before-moved case. |
| 19:52:05.000–05.954 | .955 / 0 | Component. |
| 19:52:20.969–22.036 | 1.067 / 1 | Permutation Fin-value mismatch. |
| 19:52:35.065–36.001 | .936 / 0 | Between-moved-and-split case. |
| 19:53:05.437–06.789 | 1.352 / 0 | Component. |
| 19:53:25.270–26.776 | 1.507 / 1 | Non-progressing simp. |
| 19:53:37.551–39.291 | 1.740 / 0 | Exact Other. |
| 19:53:57.766–58.132 | .366 / 0 | Full index and original rewrite candidate. |

`outerRankAtLeast` remains a model restriction, not an established source invariant. Source meaning is assumed; C++–Lean correspondence, source reachability, full native branch behavior and speedup are not proved. The accepted prior component verdicts remain at their historical revisions. No primary merge, broad build or download occurred.
