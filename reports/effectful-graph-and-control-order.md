# Fixed-schedule effectful proofs and loss of a dependency order

The pilot now proves twelve Boolean graph rewrites in an arbitrary state/error
context for one fixed topological schedule. A separate exact-source XLA replay
shows why that theorem is insufficient for effectful graph acceptance: forwarding
`And(A,false)` can make `B,A` an admissible effect order where the original data
and control path required `A,B`. Scalar/tuple values agree in this witness.

XLA pin: e58e523b11f1fde802a493a776d158007486e1bf. The canonical simplifier
has SHA256 1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f.
Lean remains 4.35.0 / Std only. All source acceptance remains zero; no semantic
census denominator is frozen. These results overlap existing source cases.

## What the fixed-schedule theorem establishes

EffectfulDag evaluates each binding once in its listed order. Operators return
an exact Except result and a state, including the state left on failure.
Parameter failure also retains state. Local deletion requires a successful
result equal to an existing reference AND an unchanged state; replacement
requires equal complete outcomes. Arbitrary suffix operators may depend on
values, modify state or fail. Reference lifting preserves shared uses and roots.

EffectfulBooleanDag embeds pure same-shape PRED operations into that language.
Seven support lemmas lift the existing twelve Boolean local laws, including
annihilators, identities, pointer-self Xor and double Not. Rank/extent remain
general; state and error types and external operations are arbitrary. An
annihilator theorem removes the pure And binding, not its effectful producer.
The prior pure graph theorems and these stronger fixed-schedule theorems remain
separately counted. Neither establishes equivalence of all permitted schedules.

EffectfulDagControls executes a shared-use suffix that emits two value-dependent
events and then changes state before failure. Old and redirected programs both
return the exact stopped error with state [7,0,0,9]. Successful shared uses,
root redirection and missing input are also checked. The negative control
rejects equal Boolean returns with different event states. Fixtures use the
existing non-module root test boundary; production additions use public modules.

## Source/API inspection

The ranges and body hashes are in census/effectful-graph-contract.json. The six
additional headers/implementations are pinned in
sources/control-effects-contract-manifest.json. Existing pinned dependencies
supply the computation, instruction and evaluator implementations.

HandleAnd's rhs-zero branch forwards the existing rhs through
ReplaceInstructionIfCompatible. That helper rejects old control predecessors,
but allows control successors. The visitor's ReplaceInstruction explicitly
relays control dependencies; its separate ReplaceWithNewInstruction has a
false default. They must not be treated as one API contract.

The computation-level replacement relays explicit old control edges, rewires
uses and removes unused operands. Its deletion worklist retains side-effectful
producers. CopyAllControlDepsTo copies explicit predecessors/successors; it does
not turn the old operand path into a new ordering edge between retained effects.
Metadata, sharding, frontend attributes, original values, status/failure and
alias/frame effects still need source-faithful contracts and proofs.

## Native diagnostic and controls

Fixture: tests/xla/control_order_replay_test.cc.
Archive: reports/control-order-replay-v1, including exact fixture/BUILD, Bazel
command/events, logs, XML and binary hash. Both original and rewritten modules
pass HloVerifier. Every candidate order is checked by native HloSchedule::Verify,
which checks complete instruction membership, uniqueness and operand/control
prerequisite order. Both custom-call actors have side effects and survive.

| Profile | No rewrite | Direct handler | Full pass |
| --- | --- | --- | --- |
| And(A,false), And control-successor B | A must precede B | B,A becomes valid | B,A becomes valid |
| Same, with explicit A control-predecessor of And | unchanged | helper skips | helper skips |
| And(A,true), And control-successor B | A must precede B | A must precede B | A must precede B |
| And(A,false), no control-successor | already unordered | remains unordered | remains unordered |

All twelve forward runs emit A,B. Every admitted reverse schedule emits B,A;
reverse schedules are rejected when the prerequisite path remains. Root tuple
values agree. RunOrder evaluates actual native instructions with HloEvaluator,
using cached substitutions and synchronous custom-call callbacks. It executes
the chosen verified schedule explicitly; the stock evaluator's traversal is
not a scheduling oracle. This is a native IR ordering/effect-callback diagnostic,
not production backend compilation or a claim about every custom-call ABI.

The Lean DependencyOrder model independently specifies complete prerequisite
schedules. Seven ControlOrder certificates prove the finite witness: all original
schedules require A before B, and the replacement admits a B-before-A schedule
whose event projection is [B,A]. The concrete graph mirrors the archived HLO;
that correspondence is reviewed evidence, not verified C++ extraction. A final
source defect verdict needs the independently reviewed observation/effect contract.

## Verification and burden

Run `python tools/checkpoint.py`. All 47 tool/evidence tests pass, as do all Lean
proofs, axiom audits, positive probes, false-proof rejection and archived native
checks. Mutation controls reject claims of source acceptance, all-schedule
refinement, production backend execution, retargeted source cases, missing native
modes and erased state on failure. check_control_effect_evidence.py enforces the
separation of proof and native diagnostic scopes.

| Lean category | Previous | Current | Added |
| --- | ---: | ---: | ---: |
| S semantics | 550 | 609 | 59 |
| H support | 631 | 731 | 100 |
| R rule proofs | 395 | 504 | 109 |
| A imports/checking | 22 | 24 | 2 |
| C certificates | 177 | 218 | 41 |
| Total | 1775 | 2086 | 311 |

Totals count the full custom Lean development; test/audit lines are separate in
reports/pilot-values.json. There are 48 value rules, 67 support lemmas, twelve
pure graph rules and twelve fixed-schedule effectful graph rules. Additional
guard/composition/oracle/order certificates have distinct report fields.
Seven new order certificates use only the audited standard axioms propext,
Classical.choice and Quot.sound; they are not mislabeled empty-axiom proofs.
All prior axiom sets and stricter historical certificate gates are retained.

snapshots/effectful-graph-pilot-v1.zip and
reports/effectful-graph-clean-replay.json preserve fresh replay without Lake
caches and compare measurements, all model probes and old axiom sets. This
replay is by the same agent, not independent semantic/source review or native
rebuilding in the fresh directory.

The next graph contract must relate observations across all schedules permitted
by data/control dependencies, or establish the appropriate refinement. Completing
that contract, API/frame correspondence, the independently reviewed semantic
census, remaining pilot families and the whole campaign/final diagnosis remain
required before answering the original research question.

Fresh Lean snapshot SHA256: 417c56876635d0e8d284a0730ae8b65f920c6eb8532a9e7931f2e9b80f62d14b.
