# Fixed tactics on 44 reviewed mathematical statements

Four fixed tactic policies jointly prove 13 of 44 selected reviewed statements.
A historical agent artifact replays all 44 from the same definitions-only imported
basis, supplying its own supporting lemmas. This is a controlled artifact replay,
not a fresh blinded agent-discovery experiment or a whole-workload verdict.

| Fixed policy | Kernel-checked targets |
| --- | ---: |
| `rfl` | 5 / 44 |
| Uniform simplification | 5 / 44 |
| Function extensionality plus uniform simplification | 8 / 44 |
| Bounded Aesop | 13 / 44 |
| Union of the four policies | 13 / 44 |
| Historical, solution-informed agent replay | 44 / 44 |

The 176 measured target/policy attempts contain 31 successful proofs and 145
unsuccessful tactic attempts, with no infrastructure or configured-budget failures.
Different policies can prove the same target; 31 successful attempts are not 31
unique targets. The eight original negative controls had a separate generator
error, described below, and do not enter these measured counts.

## What was controlled

The foundation independently reviewed at `9bcd447` contains 89 statements. We select
44 whose exact types can be restated from the chosen semantic modules without
additional project proof dependencies. The other 45 are explicitly retained as
outside this comparison, not counted as tactic failures. The subset spans exact
convolution algebra/geometry, pointwise geometry, floating negation, logical-family
coverage, finite folds/sums and contraction linearity. It includes helper and
coverage statements as well as terminal rewrite equations; it is not a sample of
all 488 retained candidate records.

Every selected header is unchanged from the reviewed version. A Lean meta-type
check confirms all 44 elaborated propositions match their original theorem types,
including quantifiers, hypotheses and result domains. The common imported basis
contains existing semantic definitions, pinned Mathlib/FloatLib, and the fixed
policy/checking infrastructure. A fresh environment guard confirms all 835
registered campaign proof names are absent before each attempt. Deliberately
importing the campaign proofs fails that guard; a changed proposition fails the
signature check. Historical proof bodies are replayed in dependency order without
importing the original project rewrite-proof modules.

The inputs and policies were frozen in local Git commit
`be93b376d74e7a1d84609de3245816d86f741845` before measured attempts. This is a local
pre-outcome checkpoint, not an independent externally timed preregistration.
Each pair runs in its own Lean process with no target-specific repair or routing.
All use the same 53-name semantic unfolding list; extensionality and Aesop policy
macros are fixed. Search bounds and a wall cap are declared in
`comparisons/fixed-tactics-v1/policies.json`. No measured attempt exhausted them.

## Meaning of the residuals

There are 31 targets outside the fixed-policy union. Their successful historical
proofs show that some misses have short, ordinary explanations. For example,
`FiniteSum.foldl_add_eq_sum` uses list induction in a six-code-line body;
`Convolution.term_kernel_add` unfolds a masked contribution and splits its case in
three body lines; `ConvolutionPointwise.elementCount_unit` uses rank induction in
six body lines. Larger convolution linearity proofs introduce a contribution
lemma and then apply a finite-sum law. These are descriptions of existing proofs,
not causal diagnoses that these exact steps are necessary.

Even the generic sum commutation/distribution statements missed by this portfolio
have one-line library proofs. The fixed policies do not include library search,
induction, Omega or every other Lean automation method. Consequently, failure here
does not show mathematical difficulty, a lower bound on proof size, or that an LLM
is necessary. The historical agent replay also has prior solution knowledge and
uses existing external proofs, including floating negation involution and sum
commutation. It establishes artifact feasibility at this basis, not a new measured
agent discovery rate, model comparison, token saving or proof-search speed claim.

## Control repair and acceptance

The first runner incorrectly emitted `unfold` on raw expressions for its eight
false-proposition controls. Their syntax failures are preserved as infrastructure
failures, not counted as proof rejection. A separately versioned control repair
removes only that invalid command; the 176 measured attempts, selected statements,
policies and imported basis are unchanged. Two Lean refutations establish that the
control propositions are false, and all eight corrected well-formed policy trials
are rejected normally. The first analysis/validator is retained and explicitly
superseded. These are development controls, not an independent held-out audit.

All accepted fixed and historical proofs pass transitive axiom checks permitting
only the standard foundation axioms. Failed declarations containing `sorryAx` in
diagnostics have nonzero exits and are never accepted. `tools/check_fixed_tactics.py`
verifies input provenance, every source/log hash, the complete attempt matrix,
signature/isolation controls and the corrected negative-control results.

## Lean size and replay

The main mathematical development remains 575 statements and 10,497 custom Lean
lines. The comparison adds a separately disclosed source inventory:

| Comparison component | Lean code lines |
| --- | ---: |
| Common statement catalogue | 350 |
| Common policy and guard automation | 153 |
| Historical replay, duplicating existing accepted source | 387 |
| All 31 accepted fixed-trial modules | 372 |
| Original failed and malformed-control trial sources | 1836 |
| Top-level operational control modules | 21 |
| Corrected unsuccessful negative-trial sources | 88 |
| Two false-proposition refutation controls | 10 |
| Total comparison inventory | 3217 |

The inventory has 202 Lean files. It includes failed/control source and duplicated
historical code; it is not a new accepted unique-development subtotal. One-line
macro invocations are charged with their full common automation. Matched-target
reference sizes and per-policy accepted-module sizes are in the structured report;
unequal accepted sets do not justify an efficiency ordering, and unsuccessful
proof sizes remain unknown. Imported libraries and existing semantic modules are
separately pinned and are not charged again as new code.

The canonical replay uses the local pre-outcome snapshot with its unchanged inputs,
`python3 tools/run_fixed_tactics.py`, followed by
`python3 tools/repair_fixed_tactic_controls.py` and
`python3 tools/check_fixed_tactics.py`. The first runner refuses to overwrite its
results; use a fresh copy of that snapshot. The repair/checker are later integration
tools supplied with the final artifact. Saved evidence can be checked directly
with `python3 tools/check_fixed_tactics.py`; historical project provenance comes
from the pre-outcome commit, while comparison inputs remain immutable.

This comparison adds no unique rewrite coverage, does not change N/F, and is not
independently reviewed. The workload still retains 488 IDs, with 244 only proposal
worksheets and zero whole records closed. Remaining formulations, full attempts,
residual interventions, matched TensorRight comparison and final independent audit
remain required. Code correspondence stays deferred future work.

The [checkpoint evidence](../reports/fixed-tactics-milestone-v1.json) records the
current 128-test curated suite, core mathematical recheck and evidence hashes.
The [validation command record](../reports/fixed-tactics-validation-v1/commands.json)
provides the replay commands and retained logs.
