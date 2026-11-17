# Independent adjudication of the held-out guard

**Verdict: final-closure scope genuinely ambiguous; candidate remains not accepted.** A fresh adjudicator, not a proof author, inspected the original baseline, operational guard and call sites, contemporaneous protocol and reviews, five rejected inverse lemmas and their imports. The actual final-environment guard invocation failed and remains preserved at [`../final-review-aa5521/checks.log`](../final-review-aa5521/checks.log); no policy, goal, manifest, or prior verdict has been changed.

## Primary historical evidence

- `1dba7c7:comparisons/heldout-space-depth-selection/GoalCandidateGuard.lean:4` describes an “environment guard for the candidate's preproof baseline.” Lines 9–20 say it rejects all names in the fixed-tactics campaign-proof inventory and implement an environment-wide check at the point of invocation. `GoalCandidateBasis.lean:1–4` applies it to the candidate baseline; `GoalCandidateLeak.lean` is the intended negative control.
- `be93b37:comparisons/fixed-tactics-v1/protocol.md:28–32` says the “common imported basis” excludes all 835 registered campaign proof declarations and the guard checks before every attempt. Lines 35–39 describe the historical agent arm replaying proof bodies from that basis with experiment-owned supporting lemmas. This strongly supports a starting-basis distinction in that protocol; it does not expressly authorize importing the five existing forbidden declarations into this separate held-out final closure.
- `b8e4661:comparisons/heldout-space-depth-selection/independent-exact-goal-review.md:25–29,35–37` accepts the frozen preproof closure, directs the eventual proof to run `exactGoal`, audit axioms and check contamination again, and requires exact statement under frozen hashes. It does not state whether the 835-name environment guard itself must pass on the final expanded imports.
- `b8e4661:comparisons/heldout-space-depth-selection/recursive-shape-split-checkpoint.md:11–15` reports a later independent review of generic splitting, and requires a separate freeze for new inputs and final independent review. It does not expressly adjudicate the inventory conflict. The final actual check and exact five-name inventory are retained in [`../final-review-aa5521/`](../final-review-aa5521/REVIEW.md).

## Lemma inspection and independence

The adjudicator read the complete definitions and proofs in `b8e4661:TensorRewrite/Pilot/FiniteProduct.lean`, `FiniteProductLemmas.lean`, `LinearIndex.lean`, `LinearIndexLemmas.lean`, and `Tensor.lean`. The three product lemmas recover/reconstruct finite-product row and column via bounded `Fin` coordinates and natural-number division; the two arbitrary-rank linear-index inverse lemmas use induction and those product lemmas. They have generic row-major semantics, no space-depth condition or desired rewrite equality, no target-specific hypothesis or circular import; empty extents are handled by absence of admitted finite coordinates. This supports their mathematical genericity, **not** their experimental independence from the explicit forbidden inventory.

No clearly established guard-clean replacement was identified. The candidate consumes these inverse results throughout several proof modules; copying, renaming or inlining them would not establish independent provenance and risks evading the guard. An alternative would require genuinely independently sourced permitted results or an explicitly authorized new proof basis and provenance audit; its cost is unknown. No repair or fresh proof worker was launched.

## Decision required and consequences

Kevin must resolve whether `noCampaignProofs` governs only the originally frozen starting basis or the entire final held-out proof environment:

1. **Baseline-only:** preserve the failed final-environment invocation, disclose reuse of the five historical proof declarations and its effect on experimental-independence accounting, and obtain a fresh independent final reviewer to apply the original guard in the explicitly intended scope. Do not say the failed invocation passed.
2. **Final closure:** current candidate remains ineligible for acceptance. A genuinely guard-clean proof with permissible provenance and fresh final review is needed; mere aliasing or inline copying is not a solution. No bounded clean substitution or cost estimate has yet been established.

If a policy change or waiver is desired, it requires an explicit owner decision; this review does not amend the contract. The exact theorem has compiled, but the original whole-case acceptance gate remains open. `outerRankAtLeast` remains a model restriction, not a source invariant; empty output domains are vacuous and C++–Lean correspondence is not claimed.

Adjudicator inspected the cited guidance, history, reviews, definitions and proofs without edits or builds. Independent adjudication ran 2026-11-17 20:02:55–20:03:40 UTC (45 s wall); coordinator began no later than 20:02:38 UTC. Active reasoning and token costs are unknown. This was not a fresh compiler replay or independent audit of the entire 58-module closure, Lean kernel or Std; the preceding replay/review remains the separate evidence at `b8e4661`.
