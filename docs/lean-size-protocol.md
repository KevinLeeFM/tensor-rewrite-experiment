# Measuring tensor-rewrite feasibility by Lean code size

[OBS 2026-11-12, current amendment] Follow [the revised plan](experiment-plan.md).
Count completed mathematical cases under the paper's assumptions; correspondence
is assumed and neither all-observation coverage nor independent per-case review
is a size/acceptance gate. Report the existing baseline, new work and total code
separately. Preserve prior proof reuse and human/author hints in provenance.
The old per-source-obligation and global-ceiling wording below is historical where
it conflicts with the new bounded campaign. No new maintainability threshold is
required before work starts. Model successes and runnable compiler bugs have
separate counts; optional extensions have separate comparison tables.

[OBS 2026-11-12] Keep L = S + H + R + A for correctness development and a separate
certificate subtotal C. When reporting total custom Lean including certificates,
label it L + C (the existing 12,341-line total uses this inclusive convention).
Operational tests/harness and failed work are separately disclosed. LOC measures
artifact burden; the plan's work-block limits prevent indefinite unsuccessful search.

[OBS 2026-11-10] Measurement companion to
[the experiment plan](2026-11-10-planning-tensor-rewrite-verification.md).
The user prefers lines of Lean as the stable primary difficulty/feasibility
measure when Codex subagents and different models contribute to one development.
The following is a proposed reproducible accounting protocol, not measured data.

## Correction to the initial chat proposal

[OBS 2026-11-10] The initial proposal centered on a fixed model, three independent
attempts per rule, 20-minute/40,000-token attempt limits and token/agent-hour
totals. That design is superseded here as the primary experiment: mixed agents,
shared learning and uneven observability make such attribution inappropriate
for the user's intended workflow. Preserve runtime/token information when
available, but missing telemetry does not invalidate artifact-size measurement.

[OBS 2026-11-10] Why the earlier framing seemed plausible: fixed-model trials
support controlled proof-search comparisons. The actual intended workflow is
collaborative construction of a reusable proof development. Measure that product
directly and reserve controlled trials for a secondary diagnostic arm.

[HYP] At fixed semantics, coverage, style and dependency baseline, the amount of
Lean needed to express and justify the rewrites is a useful proxy for the
formalization and maintenance burden. It is not a direct measurement of search
difficulty: an expensive discovery can yield a short proof, and a generic tactic
can hide substantial work behind one line. Validate this interpretation through
case studies and dependency accounting rather than assume it universally holds.

## Primary measurement: accepted Lean source lines

[OBS 2026-11-10] Count physical source lines containing Lean code after excluding
blank and comment-only content. Handle nested block comments, line comments,
strings and mixed code/comment lines lexically; do not strip comments with a
regular expression. Count a mixed line once. Record raw physical lines as a
secondary audit quantity. Pin the counter version and test its edge cases in
the experiment repository before collecting measurements.

[OBS 2026-11-10] Apply a fixed readable layout convention, based on the notebook's
[adopted Lean style](../../project-docs/implementation/lean_style.md). Pin any
formatting tool if used; do not assume one uniquely canonical Lean formatter.
Keep the convention constant across checkpoints. Do not compress declarations
onto one line or remove explanatory names to improve the score. Lexical token
counts are a secondary sensitivity check for formatting-driven differences.

[OBS 2026-11-10] The principal count L is the unique experiment-owned Lean source
needed by the accepted proof development, including semantic definitions and
custom automation. Operationally use whole required modules, with a documented
dependency/import manifest, and remove unrelated dead material during final
consolidation. Declarations used through instances, attributes, notation or
tactics must not disappear merely because textual search misses their names.

[OBS 2026-11-10] Partition L into disjoint code modules/categories:

| Symbol | Category | Included content |
| --- | --- | --- |
| S | Semantic foundation | Shapes, indices, values, operator definitions, well-formedness, observation/refinement. |
| H | Shared mathematical support | General lemmas, indexing equivalences, reduction laws and reusable proof infrastructure. |
| R | Rule-specific development | Guard/statement encodings, rule-local definitions and lemmas, accepted terminal proofs. |
| A | Checking and automation | Custom tactics, reflection procedures and soundness proofs, Lean certificate/extraction checkers used in acceptance. |

[OBS 2026-11-10] Thus L = S + H + R + A. Assign each source line once using a
reviewed module manifest; split mixed modules when needed, rather than count
the same lines in several categories. The theorem statement is not free: include
it in R, while also reporting statement/definition versus proof-body subtotals
where declaration-aware counting is reliable.

[OBS 2026-11-10] Report separately the repository's total Lean source: accepted
development L, test/control code, incomplete/abandoned branches retained for
diagnosis, and unused support. Incomplete rules do not receive an artificial
zero-line solution. Archive their attempted code and state “no accepted proof.”
Lean counterexample certificates have their own subtotal, not correctness-proof R.

## Shared dependencies and imported work

[OBS 2026-11-10] Report both per-rule local lines and each rule's dependency
closure size. Closure sizes overlap and must not be summed. A one-line terminal
proof whose new helper needs 300 lines is displayed with both numbers. At the
corpus level, count the helper once. Also report family-local totals and shared
dependencies instead of pretending an arbitrary equal allocation is causal cost.

[OBS 2026-11-10] Use three distinct baseline views:

1. Full experiment-owned L, including initial human/agent foundation work.
2. Incremental lines beyond the frozen post-pilot baseline, for the later cohort.
3. An external dependency manifest with versions, relevant imported tensor/FP
   facilities and any externally supplied rewrite proofs.

[OBS 2026-11-10] Pre-existing Lean/Mathlib/library code is not repeatedly charged
as new experiment code. Vendored or patched experiment-specific code is charged
wherever stored. Reusing an existing theorem that already proves a benchmark
rewrite is allowed only with explicit “reused proof” attribution; it demonstrates
integration coverage, not fresh agent proof discovery. Importing a tensor-specific
library must not make the project's foundational burden silently disappear.

[OBS 2026-11-10] Count generated Lean source if required for the artifact. Report
generator source separately, including non-Lean code, and never substitute the
generator's short length for the generated corpus. Compiled proof-term size and
certificate bytes may be supplementary measures but are not source LOC. Custom
external search, orchestration and extraction code gets its own language-separated
size account; externally produced certificates still require approved checking.

## What to record at each accepted checkpoint

[OBS 2026-11-10] Freeze source and dependency hashes, obligation/semantic version,
verified counts P/N and family coverage, S/H/R/A, assistance class, and measurement
tool identity. Measure mathematical and XLA-facing tracks separately; if they
share files, also provide a deduplicated combined total rather than summing them.

[OBS 2026-11-10] Preserve the first accepted solution snapshot and the final
consolidated snapshot. Record removed/added lines and changed dependencies during
refactoring. Cumulative source churn is optional evidence of exploration; it is
not a reliable estimate of human effort or agent reasoning. Rebuild and compare
theorem contracts and axiom dependencies after consolidation.

[OBS 2026-11-10] Suggested displays: overall and per-family coverage; S/H/R/A
stacked by checkpoint; distributions of local proof sizes among accepted cases;
the largest dependency closures; and a complete residual-status table. Descriptive
bands such as 1–20, 21–100, 101–500 and >500 local lines may aid reading, but are
not success thresholds. Display zero-local-line reused instances separately.

[OBS 2026-11-10] Plot coverage against total accepted Lean lines at actual
integration checkpoints. Label library versions and family composition; this
curve depends on work order. Refactoring may reduce size while preserving
coverage, so neither axis should be forced to represent monotonically increasing
effort. Do not interpret a retrospectively sorted curve as search productivity.

[OBS 2026-11-10] Report L/P as an amortized descriptive quantity only when P > 0,
alongside L, P, N, unresolved categories and the dependency baseline. It is not
the typical independent cost of another rewrite. Do not compare averages from
different semantic tracks or easier subsets without stratification.

## Feasibility interpretation and stopping

[OBS 2026-11-10] Proof feasibility is determined by accepted coverage. The size
account tells how large the successful development is and where the burden lies.
A universal upper bound on “sufficiently small” Lean does not follow from LOC.
Report the empirical size distribution and reuse structure even if no project
size ceiling has been selected.

[OBS 2026-11-10] If a maximum maintainable size is desired, select L_target after
the pilot and before the measured campaign; state whether it includes S/H/R/A,
and retain the full-L view. Exceeding it supports “missed this engineering size
target,” not “verification is impossible” or “no shorter proof exists.” Do not
select a favorable cutoff after observing the completed corpus.

[OBS 2026-11-10] LOC is an outcome metric, not a sufficient search stopping rule:
an agent can search indefinitely while adding no accepted lines. The companion
campaign therefore uses recorded strategy rounds, residual review and a global
administrative ceiling. Time/tokens need not be attributed across agents, and
they are not the primary difficulty ranking.

[OPEN] Exact baseline libraries, counter/layout versions and any L_target remain
execution-setup choices in the
[parked experiment entry](../../loose-ends/parked.md#tensor-rewrite-verification-with-mixed-agents).
