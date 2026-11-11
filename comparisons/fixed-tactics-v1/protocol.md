# Frozen fixed-tactic comparison protocol

This comparison addresses the fixed Lean tactic arm of the active mathematical
experiment. It does not settle the whole-workload research question. The target
population is a declared subset of independently reviewed mathematical statements,
with code correspondence deferred. Select the inputs and policies before the first
measured tactic attempt; do not repair individual failures during this run.

## Selection and common basis

The reviewed foundation at `9bcd44756cbf5261a0c690e05651e96fa162319a` has 89
statements. Final independent metadata recheck is preserved at `4273260`.
Current campaign/reference input revision is `5549a86b284ba3f0d57ecf331ff4f69cd5a42dbe`.
The 44 selected original headers are byte-identical to their reviewed versions.
The checked statement catalogue elaborates them into propositions, and a kernel
meta-type comparison verifies exact equality with the original theorem types.
Explicit hypotheses and arbitrary-rank/extent quantifiers remain intact.

Select all 20 basic convolution statements, four floating-negation statements,
six logical-family statements, two contraction-linearity statements, the four
finite-fold/sum statements that need no new equivalence definitions, and the eight
pointwise-convolution statements restatable from its semantic module without
proof-valued type dependencies. The remaining 45 are listed explicitly as outside
this comparison. Selection is determined by the definitions-only boundary, not
observed tactic success. It is not a representative sample of all 488 records,
and it includes support/coverage statements as well as terminal rewrite equations.

The common imported basis contains existing semantic modules, pinned third-party
libraries and the fixed tactic/guard infrastructure. It excludes every one of the
835 registered campaign proof declarations. A fresh environment guard checks all
835 names before every attempt. A deliberately contaminated environment must fail;
a deliberately changed proposition must fail the statement-fidelity check.
The catalogue contains propositions, not axioms or proofs of those propositions.

The historical agent arm replays the 44 existing proof bodies in dependency order
from that same basis, with its needed experiment-owned lemmas in the replay source.
No original project rewrite-proof module is imported. Every replayed theorem has
its exact target type and allowed transitive axioms checked. This is historical,
solution-informed artifact replay, not a fresh blinded agent-discovery trial.
Existing external lemmas such as floating negation involution and finite sum
commutation are explicitly library reuse, not newly discovered mathematics.

## Fixed policies and stopping

Each target/policy pair runs in a separate fresh Lean process. No result is
available to another attempt and no rule-specific hint, repair or routing occurs.
After unfolding its proposition and introducing its original binders, run one of:

1. `rfl`.
2. Uniform `simp_all` with the frozen semantic definition list.
3. Repeated function extensionality/introduction, then that same simplification.
4. Bounded Aesop with that same definition list.

The full 53-name list and policy macros are part of the measured custom automation;
one-line invocations do not make it free. Every attempt uses the same imports.
Search limits are 400,000 heartbeats, recursion depth 4096 and 2000 Aesop rule
applications. A 45-second per-process wall cap protects the runner; two processes
may run concurrently. Limits are secondary stopping controls, not the primary
difficulty metric. There is one attempt per pair, including unsuccessful and
budget-exhausted attempts, for 176 measured attempts. Two known false propositions
are tested against all policies as eight negative controls.

Only exit-zero results with an executed clean-environment guard and an allowed
axiom audit count as accepted. Failed propositions or an absent printout do not
count as success. Kernel acceptance is required; sorry/admit, new custom axioms,
unchecked evaluation and native_decide are not allowed. A malformed policy/input,
process crash or failed environment control is infrastructure failure and does not
demonstrate mathematical difficulty. Preserve every trial source and diagnostic.

## Accounting and interpretation

Report each policy and their union on the same 44 targets; report failed tactics,
search-budget exhaustion, wall-budget exhaustion and infrastructure separately.
Compare only matched target sets when comparing proof lines. Unknown proof sizes
remain unknown rather than zero. The same-semantic-basis agent artifact is useful
feasibility evidence, but historical solution knowledge prevents a causal claim
about fresh model discovery or an estimate of a minimum necessary proof size.

Count the unchanged main campaign separately from additional comparison code:
statement catalogue, policy/guard Lean infrastructure, successful generated proof
modules, historical replay source, and failed/control sources. List which replay
lines duplicate existing accepted source; do not present them as new mathematical
coverage. Imported library code and existing semantic/support modules remain
separately disclosed. The complete artifact inventory must expose these costs.

Independent comparison review, whole-workload N/F, remaining formulation/attempts,
residual interventions and matched TensorRight reproduction remain open. A local
baseline success or failure does not establish an all-rewrites verdict.
