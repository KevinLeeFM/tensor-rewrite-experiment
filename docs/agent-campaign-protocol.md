# Executing the TensorRight comparison with LLMs and Lean

[OBS 2026-11-12] The [updated plan](experiment-plan.md) controls scope, acceptance, effort limits
and exit criteria. It supersedes the earlier six-week, all-source-case campaign.
This guide does not resume the paused campaign or authorize new reviewer chats.

## Before assigning work

[OBS 2026-11-12] Start from the paper's implemented rules and existing Lean proofs.
Use the pinned artifact's expressions, preconditions, types and reduction hints.
Ask whether a disputed requirement is required or assumed by the paper. The
C++-to-model translation is assumed with high confidence, not proved. A brief
translation explanation replaces exhaustive correspondence work.

[OBS 2026-11-12] A task packet contains named rule IDs, exact target statements,
assumptions and existing lemmas, allowed files, the next complete result and its
work-block limit. Do not dispatch “finish Scatter” or “build a general FP library.”
Assign disjoint file ownership if delegation is authorized. Record model/role when
known, otherwise unknown. Existing packet-specific permissions do not authorize
unrelated reviewers. Do not make unavailable independent review a proof gate.

## Attempt and stop

[OBS 2026-11-12] Reuse first, then direct proof or a concrete model counterexample.
Apply the plan's two initial 20-minute blocks per unresolved rule, bounded support
work, and one selected alternate-strategy block after the broad sweep. Record
what was tried and the exact obstacle. Compilation/infrastructure failure is not
proof-search failure. Park work that expands into a framework or stops closing
named cases. Reopen only for a concrete new reason or a recorded budget revision.

[OBS 2026-11-12] The return is one of: proved model case; model counterexample;
partial result with exact remaining scope; unresolved case with a specific reason.
Include theorem/command, dependencies and incremental Lean size. For a real bug,
return a runnable pinned-XLA input, valid-before check, confirmation of the rewrite,
wrong-after observation and relevant expected behavior. A model-only mismatch
or unclear numerical permission is labelled separately.

## Trust, reuse and assistance

[OBS 2026-11-12] Lean checks proofs without sorry/admit, new axioms or native_decide.
The permitted translation assumption is outside the Lean theorem, not an axiom
that the two graphs are equal. Input validity and mathematical scalar/operator
assumptions match the paper. Verify reduction hints as mathematical facts when
used. Do not prove implementation/backend obligations absent from that model.

[OBS 2026-11-12] Existing libraries, author-supplied rule descriptions/hints and
previous project lemmas are allowed and attributed. Distinguish model selection,
shared foundation help, rule-specific help and human-written proofs. Historical
proof replay is not a fresh discovery trial. Success after assistance retains the
original outcome as well. No mandatory human attempt is required for every failure.

## Check and report

[OBS 2026-11-12] Check changed proofs and affected consumers first. Integrate in
dependency order and await prerequisite success before dependent checks. Batch
full builds/axiom accounting at useful checkpoints. Preserve immutable historical
artifacts and use a successor outcome table rather than changing their zero-closure
claims. Use small boundary/invalid-rule checks where they resolve real uncertainty.
Review a spread of complex statements and failures before the final comparison;
independent review is valuable but not required for every accepted case.

[OBS 2026-11-12] Keep model proofs, model counterexamples and reproduced compiler
bugs separate. Compare the same original cases and assumptions, never theorem
counts against case counts. Reproduce TensorRight if feasible; label author-reported
outcomes when not independently rerun. Existing fixed-tactic results are a limited,
solution-informed diagnostic, not a fresh agent baseline. Additional ablations,
blinded trials, all-case rereviews and formal extraction are optional research.

[OBS 2026-11-12] End after the bounded primary sweep, selected residual work and
report checks. A partial result can answer practical benefits/limitations. Report
whether the same original 115 successes were reproduced, which remain unresolved,
and which extra cases/bugs were found. Do not require 100% of every compiler
behavior or an ever-growing operator library before delivering the result.
