# Plan: can a mixed agent team verify every XLA algebraic rewrite in Lean?

**Current scope amendment (2026-11-10):** The user deferred code-correspondence
work and proofs. The active goal is the full mathematical proof campaign; read
[the scope amendment](theory-scope.md) before applying historical source-facing gates.

[OBS 2026-11-10] The user requested a scoped experiment based on TensorRight,
then requested an elaborated plan in notes/. They expect to use Codex subagents,
possibly with different models, and prefer lines of Lean over token/time
attribution as the primary difficulty/feasibility measure. This is a planning
record, not a completed census, implementation, or verification result.

[OBS 2026-11-10] Initial scope authorization was to write this plan. The user
subsequently authorized dependency-ordered execution of the first milestones
and activated the goal of completing the plan. See the
[initial checkpoint](2026-11-10-starting-tensor-rewrite-milestones.md).
TODO.md remains the only work queue. Keep the implementation, source
snapshots, measurement scripts, obligation ledger, logs and full reports in a
separate experiment workspace outside notes/. This investigation is independent
of SeaTypist; its language contracts and architecture do not transfer here.

## Research question and claim boundary

[HYP] A heterogeneous agent team can construct a sufficiently small, reusable
Lean development that verifies every rewrite in one pinned algebraic simplifier.
The main experimental unit is the resulting development and its coverage,
not an individual model invocation. The experiment should establish whether
this workflow succeeds and what formalization burden it leaves behind.

[OBS 2026-11-10] Operational question: can the recorded agent workflow produce
source-faithful, independently checked, rank/size-general proofs for every
obligation, with a measured amount of Lean code and disclosed human assistance?
Report correctness coverage, code burden and automation separately. Short code
cannot compensate for omitted rules or a theorem about the wrong semantics.

[OBS 2026-11-10] A positive result applies to this source revision, semantic
contract, libraries and workflow. A negative result describes the observed
limits of that workflow. Neither outcome establishes a universal claim about
all tensor compilers, future agents, or the existence of short proofs.

## Starting evidence and source pins

[OBS 2026-11-10] The attached paper reports 115/175 rules verified, with 121
expressible and 118 implemented (§8). Its evaluation uses Boolean, mathematical
integer and real tensors. The 29 layout-sensitive rules are unsupported (§10).
Reduction verification can require user-supplied index relations and additional
reasoning (§6.5). Thus its result is not direct verification of the C++ pass.
Source: Arora et al., POPL 2025, DOI https://doi.org/10.1145/3704865;
attachment: /home/k323lee/.codex/attachments/25c3ec53-e60a-48d5-a959-b5e179ea9c6e/Arora et al. - 2025 - TensorRight Automated Verification of Tensor Graph Rewrites.pdf.

[OBS 2026-11-10] Initial source inspection fetched XLA revision
`e58e523b11f1fde802a493a776d158007486e1bf`: the target file has 11,395 lines
and 58 distinct visitor handlers. These are source observations, not a rule
census. Revalidate and archive the pin at experiment setup; never use moving
main as the experimental identity. The paper's 175 is not today's denominator.
Source: https://github.com/openxla/xla/blob/e58e523b11f1fde802a493a776d158007486e1bf/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc.

[OBS 2026-11-10] Also pin Lean, standard libraries, third-party formalizations,
the TensorRight artifact and measurement tooling. The current TensorRight README
describes 125 implemented rules and 123 expected successes, different from the
paper. Recover the paper-era artifact for historical comparisons; identify
current-artifact comparisons separately. Source inspected this session:
https://github.com/ADAPT-uiuc/TensorRight#testing-your-installation.

[SUPERSEDED → 2026-11-10-formalizing-contraction-and-isolating-zero-mac.md]
The earlier “58 distinct visitor handlers” wording above counted Handle-prefixed
source definitions. Header inspection distinguishes 57 visitor override handlers
and the shared HandleAllReduceOrReduceScatter helper (header line305, same pin).
The structural count remains 58; neither count is the semantic denominator.

## Complete census before claiming coverage

[OBS 2026-11-10] Proposed census procedure:

1. Inspect every reachable transformation and graph mutation, including helper
   calls; trace matcher, shape, option and replacement-construction dependencies.
2. Assign stable source-case identifiers. Split materially different guards,
   outputs, type cases and option-dependent semantics into obligations.
3. Group related obligations into families without merging away their coverage
   requirements. One general theorem may discharge multiple cases explicitly.
4. Map every transformation site to an obligation or a reviewed non-rewrite
   explanation. Apparent unreachable cases require a source-based justification.
5. Independently reconcile the census against all handlers and mutation sites.
   Replacement-call counts, comments and unit-test counts are discovery aids.
6. Freeze obligation count N and family count F. Revisions require a denominator
   changelog and recomputation of all coverage figures.

[OBS 2026-11-10] The ledger records source locations and hashes; matched and
replacement graphs; guards; allowed dtypes, dimensions and options; helper
contracts; semantic track; statement identity; proof/dependency identities;
review status; assistance provenance; final outcome; and artifact-size fields.
No operator is dropped because its semantics or proof is difficult. External
helpers belong to the dependency boundary even if their source is in other files.

## Semantic contract and verification target

[OBS 2026-11-10] The general obligation is: for every legal graph, tensor input
and permitted configuration satisfying the actual rewrite guard, the replacement
is well formed and preserves the required observations. Include shapes, types,
index bounds, layout, dynamic dimensions, tuples and effects wherever relevant.
Use behavior refinement rather than deterministic equality when the independently
specified operator contract permits multiple behaviors.

[OBS 2026-11-10] Preserve unbounded rank and size where the source permits them;
do not prove a few concrete shapes and extrapolate. Source-imposed fixed ranks
are legitimate. Distinguish unbounded mathematical index arithmetic from actual
finite-width value and attribute arithmetic. Cover empty dimensions, exceptional
values and boundary cases where allowed by the source contract.

[OBS 2026-11-10] Maintain two semantic tracks. The mathematical track matches
TensorRight's abstractions for a fair comparison. The XLA-facing track covers
the source's finite-width arithmetic, floating point, layout and option contracts
and determines the whole-file outcome. A rule can succeed in one and remain
unresolved in the other. Each success states its semantic track explicitly.

[OBS 2026-11-10] Concrete warning from the inspected source: `A - A => 0` is
guarded by integral type or fast math at lines 2457–2463. A real-number proof
does not establish unrestricted floating-point equality. XLA also permits
reassociation of reductions. Define permitted behavior independently of the
rewrite being justified; do not make a desired rewrite an axiom of fast math.
Unclear option/custom-call contracts are recorded specification gaps.
Sources: pinned file above; https://openxla.org/xla/operation_semantics#reduce.

[OBS 2026-11-10] A reviewed source-to-theorem translation remains a trust
boundary. Differential tests strengthen its evidence but do not prove the
translation universally correct. Claim source-linked rewrite verification;
do not claim machine-checked correctness of the entire compiled C++ pass without
an additional verified extraction/refinement argument. Record that stronger
boundary as a possible later experiment, not a hidden requirement of this one.

## Staged development and deliverables

[OBS 2026-11-10] Proposed stages and completion evidence:

| Stage | Deliverable and gate |
| --- | --- |
| Setup and census | Pinned inputs, full source-case map, independently reconciled N/F, dependency boundary. |
| Semantics and pilot | Approximately 20 diverse cases; reviewed operator meanings and observation relations; code-count convention tested; pilot distinguished from evaluation. |
| Full campaign | Every obligation receives extraction and proof work, including hard/unsupported cases; shared library changes enter versioned integration checkpoints. |
| Diagnosis | Residuals classified; representative corrected-statement, missing-lemma and alternate-strategy interventions; counterexamples validated. |
| Consolidation | Accepted code deduplicated without changing theorem contracts; first-accepted and final sizes both preserved. |
| Final audit | Clean proof replay, axiom/statement/dependency checks, source review, count reconciliation, controls and explicit verdict. |

[OBS 2026-11-10] Pilot selection spans simple arithmetic, advanced numerical
operations, indexing/slicing, reshape/layout, reductions and conditional rules.
Its purpose is to expose semantic and measurement defects early, not to select
only easy rules. Shared foundations may continue to grow during the full
campaign; freeze semantic meanings and version reviewed extensions explicitly.

[OBS 2026-11-10] Proposed foundation covers arbitrary finite shapes, indexing,
operator meanings, well-formedness, observation/refinement, permutations,
linearization, finite reductions and required scalar/layout models. The actual
census determines details. All newly written foundations count toward the
project's Lean size, regardless of whether a human or agent wrote them.

## Evidence needed at the final exit

[OBS 2026-11-10] Positive whole-file proof outcome requires complete census
coverage, accepted general proofs for all N obligations in the XLA-facing track,
no hidden strengthened premises or unresolved semantic gaps, clean independent
replay and passing validation controls. Report separately whether this was
autonomous after the reviewed foundation or required rule-specific human help.

[OBS 2026-11-10] Negative workflow outcome requires the complete census to have
received the documented campaign, reproducible residual failures, diagnosis of
representative failure classes, and infrastructure problems isolated or repaired.
It supports “this workflow did not suffice under the recorded stopping policy,”
not “no Lean proof exists.” A valid counterexample is a verification success
for bug detection but prevents the claim that every original rewrite is correct.

[OBS 2026-11-10] A broken harness, incomplete census or unaudited semantics
leaves the research question unresolved. Keep the exit gate open; administrative
termination yields an incomplete report, not an invented positive/negative
answer. There is no scientifically sound guarantee of a binary answer merely
because a calendar or code budget has been exhausted.

[OBS 2026-11-10] Final report sentence: “Workflow W, using dependency baseline B,
verified P/N source obligations in track T with L lines of experiment-owned Lean
(S semantics, H shared support, R rule-specific, A checking/automation), and
required assistance class Q. The remaining obligations failed for reasons D.”
Give all categories and uncertainty, not just the compact sentence.

## Companion protocols and next decisions

[OBS 2026-11-10] The elaborations are
[Lean-size measurement](2026-11-10-measuring-tensor-rewrite-lean-size.md) and
[mixed-agent execution and diagnosis](2026-11-10-running-tensor-rewrite-agent-campaign.md).
Together these form one plan; TODO.md owns scheduling and status.

[OPEN] Execution workspace, historical artifact mapping, semantic contracts,
administrative stopping ceiling and any desired maximum maintainable code size
must be recorded before the corresponding measured campaign. See
[the resumable entry](../../loose-ends/parked.md#tensor-rewrite-verification-with-mixed-agents).
