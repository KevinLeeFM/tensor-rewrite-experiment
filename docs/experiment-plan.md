# Experiment plan: LLMs and Lean on TensorRight's task

[OBS 2026-11-12, adopted user instruction] This revision replaces the 10 November
execution plan. The objective is to prove as many mathematical rewrite rules as
possible with little effort, or disprove actual implementations with runnable
counterexamples. Correspondence between the translated model and C++ may be
assumed with high confidence, just as for the paper's human-written translations.
It is not a theorem we must prove. This update changes planning; the verification
campaign remains paused until resumed. TODO.md remains the only scheduling index.

[OBS 2026-11-12] Whenever scope is unclear, ask:
**“Is this required or assumed by the XLA rewrite paper we are comparing against?”**
If required, verify it. If assumed, record the assumption and proceed. If absent
from the paper, classify it as an optional extension, not a baseline gate. Consult
the paper/artifact first; do not escalate every routine choice to the user.
A genuinely ambiguous assumption affects that case, not all other work.

[OBS 2026-11-12] The previous plan is preserved in
[the historical snapshot](history/experiment-plan-before-2026-11-12.md).
The [retrospective](#what-the-first-day-taught-us)
explains the correction: useful proof construction outpaced case completion.
The prior whole-file/all-observations gates, compulsory independent review of
every extension, mandatory human interventions and proposed six-week schedule
are superseded. They are not prerequisites for answering the paper-level question.
Why the earlier plan went wrong: it treated stronger implementation assurance as
necessary for comparing mathematical rewrite verification, and kept expanding support.

## Question and useful outcomes

[HYP] An LLM using Lean and existing libraries can reproduce TensorRight's model
verification results with manageable new Lean code, and may resolve additional
rules or find implementation bugs that its model does not expose.

[OBS 2026-11-12] Report three separate answers:

1. Can the workflow prove the same mathematical rules under the paper's assumptions?
2. What additional rules or runnable compiler counterexamples can it obtain cheaply?
3. What effort, code burden, assistance and recurring failure modes does it leave?

[OBS 2026-11-12] A **case** is one named optimization with a fixed original
calculation, replacement, applicability conditions and mathematical data types.
A **model proof** is a Lean proof that the two calculations give the same shapes
and values for every permitted input. An **implementation counterexample** is a
runnable input on which the real pinned pass changes an observable result or
turns a valid program into an invalid one. A model-only counterexample disproves
only the translated rule until reproduced in the implementation. These are the
terms to use in user reports; helper-theorem counts are not completed-case counts.

## Match the paper before extending it

[OBS 2026-11-12] Primary sources: Arora et al., POPL 2025,
[paper](https://lsrcz.github.io/files/POPL25.pdf), especially §§3–6, 8 and 10;
[paper-era artifact README](../sources/tensorright/artifact/tr-artifact/README.md);
[recovered rule inventory](../census/historical-rules.json).
The artifact is already pinned at Zenodo DOI 10.5281/zenodo.14159871.
Use it, not the moving GitHub rule collection, for the historical comparison.

[OBS 2026-11-12] The paper counts 175 rules, 121 expressible, 118 implemented,
115 proved and three implemented rules timing out. The primary attempted-case
set is the **118 implemented artifact rules**, retaining their original identities
and per-rule types/conditions. Record the other 57 as outside the paper's executed
set, distinguishing unimplemented-but-expressible from unsupported where known.
The original 115 successes are the reproduction target; a different collection
of 115 successes does not establish reproduction of those results.
Select the main suite using both `included_by_runall` and nonempty
`verifier_invocations` in the recovered inventory: it contains 122 declarations,
but only 118 invoked main-suite rules. Do not count unused/debug declarations.

[OBS 2026-11-12] The newer pinned C++ collection has 488 retained candidate
entries. Keep all entries and their provenance, but do not equate them to the
paper's 175 or to 488 independent completed mathematical questions. Mapping the
118 models does not require first proving an exhaustive taxonomy of that file.
Map relevant entries incrementally; keep ambiguous and many-to-one mappings visible.
The extension table covers the retained collection, with unsupported/unattempted
rows explicit. No whole-file guarantee is required to finish the primary comparison.

[OBS 2026-11-12] Use the following scope decisions. “Required” means required for
our Lean counterpart of the paper's claim, not a claim that the paper used Lean.

| Topic | Treatment in this experiment |
| --- | --- |
| Original/replacement tensor expressions and stated conditions | Translate explicitly and check the modeled rule. |
| Shapes, legal accesses and value equality | Prove as needed by that rule; paper §6.4. |
| Arbitrary dimension counts and sizes admitted by the model | Required; fixed examples alone do not establish success. |
| Boolean, mathematical integer and real arithmetic | Primary scope; use existing verified library facts. |
| Reduction index relations and algebra used in the paper | Reuse disclosed hints; prove the corresponding mathematical obligation, not just assume the target equality. |
| Human-written DSL faithfully describes the C++ rule | Adopt the same translation assumption for agent-written Lean, with a short confidence explanation. |
| Valid source graph, legal input attributes, scalar/operator meanings | Explicit model premises/definitions, not proofs about every C++ caller or backend. |
| Correct Lean/kernel and imported library foundations | Trusted baseline; record versions and axiom checks, do not reverify the toolchain. |
| C++ translation correctness, mutation effects, allocation, backend schedules | Not required for the baseline; do not build a compiler-verification framework. |
| Actual finite-width arithmetic, IEEE rounding/NaNs, layout/bitcast, unsupported operators | Separate optional extensions; never gates on exact-number model proofs. |
| Running XLA to confirm a proposed implementation bug | Required for that bug claim; not required for every positive model proof. |

[OBS 2026-11-12] “Correspondence assumed” is an external interpretation of the
proved model, not permission to add Lean axioms or assume the desired equality.
Do not silently strengthen conditions, discard empty shapes admitted by the
original model, fix dimensions, or replace an operator with its desired answer.
Use actual paper definitions/hints when evaluating the paper task. If an existing
Lean model differs, record and resolve the mathematical difference, or report it
as a different case. A real-number proof is not an IEEE proof.

## Translation confidence without a correspondence project

[OBS 2026-11-12] For each case, record a compact explanation (normally a paragraph):
source/artifact location and pin; original and replacement calculations; conditions;
modeled data types; intentional abstractions; why the Lean statement represents
that rule. Read the relevant C++ branch/helper when needed, rather than relying
only on comments or names. For the historical comparison the artifact rule fixes
the target; record differences from the newer C++ revision instead of combining them.

[OBS 2026-11-12] Existing source inspection and model tests may support confidence.
Add small executable boundary checks when they resolve a concrete doubt. A simple
rule needs no large differential-test suite. Mark unresolved translation doubts
on the affected row; do not count a dubious translation as a success. Independent
review is useful selectively for difficult translations or final sampling, but
is not a mandatory per-case acceptance gate and does not certify correspondence.

## What the first day taught us

[OBS 2026-11-12] At `ab09a4e`, 727 checked theory statements and 12,341 custom Lean
lines include reusable models, support, rewrite proofs and refutations. Six declared
groups of mathematical transformations have complete proofs under their stated
conditions. These are existing assets to reuse, not a new paper-level success count.
The ledger records 206 candidate entries with proposal-only worksheets, and the
paper comparison has not yet been performed. Full data and limits are in the
[checkpoint report](../reports/bit-packing-milestone-v1.json).

[OBS 2026-11-12] What worked: existing scalar libraries, bounded index maps,
proofs preserving contribution order, and explicit counterexamples to weakened
conditions. What must change: the existing generator hard-codes zero completed
records and an unfrozen denominator, and the validator requires those values.
Build a small successor table that can recognize completed model cases; leave
historical manifests/reports unchanged. Do not rewrite the old entire pipeline.

[OBS 2026-11-12] Do not spend the next phase clearing all 638 later statements'
independent-review backlog, finishing every float/layout adapter, or constructing
a general Scatter framework before completing ordinary model cases. Existing
proofs can immediately discharge matching cases once their statements and
assumptions are checked. Four fixed tactics solved 13 of 44 selected statements;
historical agent proofs replayed all 44, but that was solution-informed replay,
not a fresh measured LLM discovery rate. Retain that distinction.

## Refreshed execution order

[OBS 2026-11-12] Dependencies determine order within this priority list. Start
with reuse and complete rule statements, not another general library milestone.

1. **Create the comparison table.** One row per historical implemented rule,
   exact type/condition scope, existing proof links, translation-confidence note,
   original TensorRight outcome and current Lean outcome. Freeze this 118-case
   input list. Keep the larger candidate collection separately. Do not freeze a
   new global family/partition denominator before starting useful proofs.
2. **Credit existing complete proofs.** Match exact statements, build them and
   inspect assumptions. Record a rule as proved once all of its declared paper
   types/variants are covered. Missing machine-float or layout results do not keep
   a real-number rule open. Keep partial variants explicit, counted once per case.
3. **Make a broad inexpensive sweep.** Use imported lemmas, simplification,
   arithmetic tactics, extensionality and short induction first. Attempt every
   remaining primary case or name its concrete missing-model dependency. Do not
   complete a general operator library just to reach the next case.
4. **Resolve high-value residuals.** Add the smallest shared lemma/model fragment
   that closes named cases; then immediately finish those cases. Give difficult
   residuals one different bounded strategy and preserve failures. Finish the
   primary comparison before selecting substantial extensions.
5. **Run promising bug witnesses.** Reuse archived XLA fixtures and working build
   caches. Confirm suspected failures in the real pass; minimize and archive the
   input, command, options, before/after result and expected behavior. A cheap,
   compelling witness may interrupt the model sweep; infrastructure rebuilding
   must not stall unrelated proofs.
6. **Compare and close the report.** Attempt a paper-artifact rerun with its stated
   settings; distinguish reproduced results from author-reported results if the
   environment prevents it. Recheck accepted Lean proofs, summarize residuals and
   state the feasibility result with the limits below.
7. **Choose extensions by expected payoff.** Prefer existing nearly complete work,
   additional mathematical rules and concrete bug candidates. Keep word/IEEE,
   layout, Gather/Scatter and other extensions separate from baseline results.
   Retain all candidate rows; unsupported does not mean disproved or impossible.

## Bounded effort and rules against unproductive work

[OBS 2026-11-12] The following are adopted scheduling defaults for the next run,
not scientific bounds on proof difficulty or token attribution across agents:

- First try reuse or a direct proof. Use at most two distinct 20-minute work
  blocks per unresolved case in the initial sweep. Stop earlier on a clear barrier.
  Check elapsed time at tool/message boundaries. Compilation delays are recorded
  separately; do not repeatedly extend a block because no proof was produced.
- A support task must name the terminal cases it should close, the exact missing
  fact and a bounded deliverable. Give it one 20-minute block before reconsidering
  scope. If it becomes a framework, stop and classify the dependency.
- After the broad sweep, allow one additional 20-minute alternate-strategy block
  for a selected high-payoff residual. Reopen later only for a concrete new lemma,
  model correction or explicit decision recorded before the next attempt.
- A task that closes no case must identify a specific prerequisite removed and
  immediately name its next terminal proof. Two consecutive work blocks without
  either result trigger parking, not another generic extension.
- Use targeted build/tests for the changed proof and its consumers. Batch full
  audits at integration/release points; do not regenerate every historical packet
  after every lemma. Preserve failures, but avoid ceremonial reporting overhead.
- Optional extensions receive a declared batch and effort cap before starting.
  No unbounded continuation after the primary comparison. The finite sweep can
  end with unresolved cases; the final analysis is then still required.

[OBS 2026-11-12] These caps may be revised explicitly before another batch when
new evidence justifies it; preserve previous results and explain the change.
Lean LOC remains the primary code-burden measure. Rough work-block counts and
elapsed totals expose wasted effort without requiring reliable per-model tokens.
A long proof is not automatically bad; its resolved cases and reuse must justify it.

## Outcomes and acceptance

[OBS 2026-11-12] Keep model and implementation outcomes in separate columns:

| Model result | Minimum evidence |
| --- | --- |
| Proved | Exact intended statement, all declared types/conditions covered, passing Lean build, allowed axioms only, translation assumption/confidence recorded. |
| Disproved in the model | Concrete valid input and differing shape/value, checked by a Lean certificate or reproducible model evaluation; identify which kind. |
| Partial | Explicit proved subcase and exact remaining conditions/types. |
| Unresolved | Reason: missing model, uncertain translation, unsuccessful bounded proof search, timeout or infrastructure. |

[OBS 2026-11-12] Independently label implementation results as **bug reproduced**,
**behavior difference with contract unsettled**, or **not established**. A runnable
bug needs a valid original input, evidence that the relevant pass performed the
change, and an invalid output or difference forbidden by the stated contract.
A harness crash, timeout, model-only witness, or allowed fast-math difference
is not automatically a compiler bug. A Lean refutation certificate is useful
but not required in addition to a decisive runnable implementation counterexample.
No positive model proof is labelled “bug-free C++.”

[OBS 2026-11-12] A counterexample to a rule TensorRight proved under supposedly
identical assumptions requires diagnosis of translation/model/tool differences
before credit. Do not silently repair the target and replace the original result.
Source bugs and model proofs can coexist because the translation is assumed.

## Fair measurement, comparison and final answer

[OBS 2026-11-12] Report proved model cases, model refutations, reproduced compiler
bugs and unresolved cases separately. Retain the original paper's per-case result;
keep hints, imported proofs, previous project proofs and human assistance visible.
Reusing the authors' rule descriptions and reduction hints is allowed because the
paper's workflow required them. That tests proof construction given a translation;
it does not establish unaided extraction or independent discovery.

[OBS 2026-11-12] Report existing baseline Lean, incremental Lean and their total,
with semantics, shared lemmas, case proofs, automation and certificates separated.
Do not count imported library source as new work. Count whole required custom
modules, not only short final proof bodies. Show local and shared costs; unknown
proof sizes are unknown. Record existing 12,341 lines as historical investment,
not code that a fresh run necessarily needs in full. Helpers and dtype instances
must not inflate the number of completed rules. Use the existing counter/style.

[OBS 2026-11-12] The final gate is a complete, bounded **comparison report**, not
proof of every compiler rule. It requires an outcome for each of the 118 primary
cases, replayable successes/witnesses, explicit unresolved reasons, preserved
assumptions and assistance, code counts, and a case-by-case comparison to the paper.
An absent artifact rerun must be disclosed as author-reported comparison, not
claimed independent reproduction. Check a small spread of difficult statements
and failures for mistranslation/vacuity; independent review is valuable when
available, but neither all-statement rereview nor a human proof attempt is mandatory.

[OBS 2026-11-12] State explicitly whether the workflow reproduced the original
115 successful rules, which it missed, which additional rules it resolved, and
which actual bugs it reproduced. Missing successes after the bounded campaign
support “this workflow did not reproduce the paper's coverage under this budget,”
not “LLMs cannot verify these rules.” Bugs found do not cancel missing positive
proofs. If evidence/semantics remain too uncertain, say the comparison is incomplete.
A partial but valid result can establish practical benefits and drawbacks without
claiming full reproduction. Do not manufacture a universal yes/no verdict.

[OPEN] The next implementation action, once the campaign resumes, is the small
comparison table and reuse of existing proofs. See the
[resumption entry](#refreshed-execution-order).
The [measurement companion](lean-size-protocol.md) and
[campaign companion](agent-campaign-protocol.md) adopt this
revision. No new proof campaign or counterexample run is performed by this plan update.
