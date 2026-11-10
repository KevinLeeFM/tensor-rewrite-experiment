# Running and judging a mixed-agent tensor-rewrite campaign

[OBS 2026-11-10] Execution companion to
[the experiment plan](2026-11-10-planning-tensor-rewrite-verification.md) and
[Lean-size protocol](2026-11-10-measuring-tensor-rewrite-lean-size.md).
This specifies a future workflow using Codex subagents, potentially of different
models. No agents or experiments were launched to write these notes.

## Team organization and provenance

[OBS 2026-11-10] Proposed roles are coordinator/integrator, census/formalization
workers, shared-library workers, rule-proof workers and reviewers. A person or
agent may fill multiple roles, but avoid self-review for accepted source mappings
and semantic changes. An agent reviewer is a separate inspection, not a trusted
oracle; final source correspondence needs accountable human review or a checked
translation argument. Lean acceptance alone cannot establish that correspondence.

[OBS 2026-11-10] Assign work by coherent rewrite family and shared prerequisites,
not one model call per theorem. Use disjoint file ownership or isolated checkouts
and explicit integration to prevent concurrent edits from invalidating evidence.
The coordinator owns semantic interfaces, the obligation ledger and checkpoint
selection. Proof workers propose semantic changes for review rather than edit
protected definitions to make goals easy.

[OBS 2026-11-10] Each task packet identifies source cases, source/dependency pins,
semantic track, required generality, frozen definitions, allowed file scope,
existing lemmas and required result format. Workers return a patch, theorem
identities, a source-to-statement explanation, a dependency list, verification
output and unresolved issues. Record a task/parent identifier and model/config
when observable; explicitly mark unknown fields. No inference from agent names.

[OBS 2026-11-10] Keep lightweight model/role provenance for descriptive analysis.
The evaluated system is the whole recorded workflow. Do not infer which model is
better from unequal assignments, shared lemmas or selectively routed hard cases.
Branch outcomes are correlated because agents share definitions and discoveries.
Exact attribution of tokens, thinking time and ownership of every line is optional.

## Automation and assistance classes

[OBS 2026-11-10] Separate these kinds of human participation in the ledger:

| Class | Example | Interpretation |
| --- | --- | --- |
| Evaluation/setup | Choose source, review meanings, audit statements, reject invalid artifacts. | Compatible with automatic proof construction given reviewed foundations. |
| Foundation contribution | Supply or repair tensor definitions or general supporting lemmas. | Count source and disclose baseline/extension provenance. |
| Rule-specific assistance | Correct the worker's statement, suggest its bijection, supply a lemma or proof step. | Assisted result; cannot silently join the autonomous numerator. |
| Human proof | Write the substantive rule proof. | Formal feasibility evidence, not autonomous proof success. |

[OBS 2026-11-10] Preserve the pre-assistance outcome and later assisted result.
Human contributions to shared lemmas can affect many rules; propagate provenance
through their dependencies rather than label only the directly edited rule.
Likewise record use of existing TensorRight encodings/hints or published solutions.
Such use may be a legitimate assisted workflow but does not test unaided extraction.

[OBS 2026-11-10] Freeze the reviewed starting foundation after the diverse pilot.
Allow new agent-proved general lemmas during evaluation, with reviewed versioned
integration. Report this as a learning/shared-library campaign. Pilot solutions
are part of final corpus coverage but are separated from later evaluation results.
Do not call successive attempts independent when the library or prompts carry
earlier solutions.

## Campaign rounds and administrative scope

[OBS 2026-11-10] Proposed finite work policy, replacing fixed per-call quotas:

1. Initial sweep: every source obligation receives extraction and a proof attempt,
   or an explicit dependency/semantic failure record with a concrete blocker.
2. Shared-support sweep: integrate reviewed general lemmas and missing operator
   support; revisit all affected residuals rather than only promising examples.
3. Alternate-strategy sweep: every residual receives a documented different
   approach, such as index equivalence, structural induction, arithmetic
   normalization or reduction decomposition, or a specific model/contract barrier.
4. Diagnostic closeout: review every residual's classification and investigate
   a stratified sample in depth. A “ran out of ideas” note alone is insufficient.

[OBS 2026-11-10] These rounds are workflow stages, not comparable units of
reasoning effort. Record start/end checkpoints, strategies and outcomes rather
than count every chat turn as a trial. A worker may use subagents within the
assigned scope; those contribute to the same workflow provenance and code total.

[OBS 2026-11-10] Suggested scheduling envelope is six weeks: census/contracts
(week 1), foundations/pilot (weeks 2–3), full sweeps (weeks 4–5), diagnosis/audit
(week 6). This is a proposal, not a prediction that all semantics fit in two weeks.
At setup choose a global calendar/spending ceiling and reserve capacity for every
family and final diagnosis. No per-agent time accounting is required. If the
ceiling prevents the evidence gates, report incomplete and specify what remains.

## Acceptance checks and negative controls

[OBS 2026-11-10] Accepted proofs require a clean pinned build and theorem/semantic
identity checks. Inspect transitive axiom dependencies against an allowlist of
standard foundations; reject sorry/admit, unapproved axioms and unchecked
evaluation/solver shortcuts. A plausible theorem name or a successful build
alone is insufficient. Inspect the elaborated assumptions for vacuity, hidden
typeclass laws, strengthened guards and fixed-size specializations.

[OBS 2026-11-10] Source review verifies both directions of extraction coverage:
the theorem applies whenever the actual source guard permits the transformation,
and its replacement matches what the source constructs. A syntactic guard can be
stronger than the theorem's assumptions, but any implication used must be
justified. Require shape/type validity and relevant context/effect preservation.
Confirm plausible legal instances without treating witnesses as a general proof.

[OBS 2026-11-10] Differential controls instantiate small/boundary cases in both
the semantic model and pinned XLA, confirming the intended rule fires and its
replacement corresponds. Include empty dimensions, large-index boundaries and
exceptional numerical values when permitted. Failed execution must not be
interpreted as semantic inequality. These checks supplement the proof and audit.

[OBS 2026-11-10] Include independently validated invalid-rule controls: remove a
necessary guard, alter an axis/permutation or change a numerical condition.
Retain witnesses establishing that the mutation is actually invalid. Separate
development controls from held-out audit controls. Any invalid theorem accepted
as a source-faithful success blocks release and triggers an acceptance audit;
repair it and revalidate affected proofs before interpreting coverage.

[OBS 2026-11-10] External search/SMT may propose proofs or witnesses, but positive
verification needs a Lean-checked argument within the approved trust boundary.
For each counterexample, validate actual guards and the intended observation
relation, check an executable witness where possible, and reproduce the rewrite
in XLA. Prefer a Lean refutation certificate. An IEEE discrepancy under an
option permitting other behavior is not automatically an XLA bug.

## Outcomes, diagnosis and comparisons

[OBS 2026-11-10] Every obligation has one primary status: verified, refuted,
extraction failure, semantic gap, proof-search failure, or infrastructure failure.
Record stronger-assumption/bounded proofs as partial artifacts under the remaining
failure status. Distinguish primary cause from secondary blockers. Infrastructure
retries must not count as evidence that the mathematical problem is hard.

[OBS 2026-11-10] For up to 20 residuals selected by a documented stratification,
test corrected statements, independently proved missing lemmas, alternate proof
strategies and a human Lean attempt. Cover each observed failure class where
possible and include hard layout/numerical/reduction cases; enlarge the sample
if 20 cannot cover the classes. Report how the intervention changes both accepted
coverage and new Lean size. Leave the original autonomous status intact.

[OBS 2026-11-10] Comparisons: reproduce TensorRight on a mapped historical subset
under matched semantics; run fixed Lean tactics on reviewed statements to expose
the agent's additional role; and compare source extraction with reviewed-statement
proof construction on a stratified subset. Use equal frozen library inputs for
controlled comparisons. A fully learned library containing the answers is not
a fair no-LLM baseline. Keep these comparisons distinct from the evolving campaign.

[OBS 2026-11-10] Evaluate whether difficult residuals are short proofs waiting
for an insight, missing reusable theory, unclear semantics, source-extraction
mistakes, or a genuinely large accepted development. Small successful scripts
alone cannot distinguish these causes. Do not count unknown proof sizes as zero
or infer minimum proof length from unsuccessful search.

## Final report and handoff

[OBS 2026-11-10] Release the external experiment repository with source and
dependency pins, census, semantic contracts, accepted proofs and refutations,
statement/axiom/source reviews, lightweight task provenance, control evidence,
first-accepted/final checkpoints, reproducible LOC tooling and outcome tables.
notes/ retains the interpretation and links, not logs or full result tables.

[OBS 2026-11-10] Report full-corpus closure and automation independently: 100%
assisted proofs establish formal feasibility with assistance, not autonomous
success. A workflow that validates incorrect rules by refutation can be useful
even when “all original rewrites are correct” fails. High partial coverage may
support practical usefulness while the strict whole-file target remains unmet.

[OBS 2026-11-10] Code burden is a measured dimension of the verdict, with an
optional preregistered maintainability target. A one-line proof of a weakened
statement fails; a large correct development succeeds formally but may miss that
engineering target. Give explicit reasons for the positive/negative workflow
verdict and preserve any unresolved validity conditions.

[OPEN] Before execution, resolve the setup choices in the
[parked experiment entry](../../loose-ends/parked.md#tensor-rewrite-verification-with-mixed-agents).
