# Discarded prerequisites across the Boolean pilot family

The native ordering diagnostic now covers all twelve Boolean pilot branches.
Every branch can discard an operand or inner Not that carries a control
prerequisite, allowing a reversed pair of effect callbacks after the rewrite.
This includes value identities. A test-only A-to-B dependency excludes that
reverse order again. This is source-linked diagnosis, not accepted whole-source
verification or a production repair.

Source pin: XLA e58e523b11f1fde802a493a776d158007486e1bf; target SHA256
1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f.
Lean remains 4.35.0 / Std only. Source acceptance remains zero and no semantic
census denominator has been frozen.

## Why identities also need graph reasoning

The original witness placed effect A directly on a discarded data operand of
And(A,false). The new recipes instead give A a control edge into whichever
operand the rewrite discards. In an identity, that operand is the constant;
in an annihilator, it is the other value producer. Double Not puts the control
edge on its inner Not. Pointer-self Xor controls the common producer.

An independent pure custom call supplies the nonconstant Boolean value. Effects
A and B are synchronous mock custom calls with has_side_effect=true. The old
Boolean node is a control predecessor of B; the root contains its value and B's
value. Originally, A's control/data path requires A before B. Forwarding or
replacing the Boolean node removes that path even though A and B survive.

The pinned HloInstruction header states that control predecessors must execute
before their instruction (1393–1400), and describes control edges as additional
ordering requirements (1346–1354). The replacement helper checks only the old
node's control predecessors, not those of discarded operands. The computation
replacement can remove unused operands while ignoring their control edges.
SafelyDropAllControlDependencies reconnects explicit predecessor/successor pairs
(instruction.cc3270–3282); it does not recover a path through a removed data use.
Existing full-file source hashes and the source-case function hashes are pinned
in census/effectful-graph-contract.json and census/boolean-control-family-contract.json.

## Native matrix

Fixture: tests/xla/boolean_control_family_replay_test.cc.
Successful immutable archive: reports/boolean-control-family-replay-v3.
It contains the exact fixture, BUILD, command/events, logs, XML and binary hash.
The canonical simplifier implementation is unchanged.

| Source branch | Discarded controlled node | Direct handler / full pass |
| --- | --- | --- |
| HandleAnd/rhs-true | true constant | new B,A order |
| HandleAnd/lhs-true | true constant | new B,A order |
| HandleAnd/rhs-zero | nonconstant value | new B,A order |
| HandleAnd/lhs-zero | nonconstant value | new B,A order |
| HandleOr/rhs-true | nonconstant value | new B,A order |
| HandleOr/lhs-true | nonconstant value | new B,A order |
| HandleOr/rhs-zero | false constant | new B,A order |
| HandleOr/lhs-zero | false constant | new B,A order |
| HandleXor/rhs-zero | false constant | new B,A order |
| HandleXor/lhs-zero | false constant | new B,A order |
| HandleXor/equal-inputs | pointer-identical common producer | new B,A order |
| HandleNot/involution | inner Not | new B,A order |

Each rule has three profiles and four modes:144 runs in total.

- Discarded-control profile: the control edge enters the discarded node and the
  old node controls B. All twelve full-pass and direct-handler rewrites admit
  the previously forbidden B,A schedule. Adding A→B after the full pass restores
  the required order in all twelve repair runs.
- Old-control profile: the control edge enters the node being rewritten.
  Eleven cases are skipped by ReplaceInstructionIfCompatible. Pointer-self Xor
  calls the visitor's ReplaceInstruction directly, rewrites and relays the old
  explicit edge. None introduces a reverse order; none needs an added repair.
- No-successor profile: B has no old control predecessor. B,A is already legal;
  these twelve rewrites do not introduce an order change.

Every profile also has a no-rewrite mode. Both modules pass HloVerifier. Native
HloSchedule::Verify checks all instruction membership, uniqueness and data/control
prerequisites for every candidate schedule. Actual HloEvaluator instructions run
in each accepted order using cached substitutions; callbacks emit the event trace.
All forward traces are A,B. All accepted reverse traces are B,A; root tuple
values agree. The candidate scheduler permits pure prerequisites before B, so
it does not confuse a bad placement of a pure node with an impossible actor order.
This is native IR/schedule/callback evidence, not compiled backend execution or
a proof about every custom-call ABI. PRED scalar and pointer-self limits remain
explicit; these 12 rows are not 12 accepted general source proofs.

Two failed archives remain immutable. V1's fixed-priority reverse candidate put
B before a surviving pure prerequisite, producing assertion failures. V2's
native assertions passed, but buffered stdout interleaved with verifier stderr,
violating the complete-row archive gate. V3 fixes both harness issues and passes
all144 assertions/row checks. The evidence validator retains the failures as
failures instead of retroactively promoting them.

## Refinement and review integration

DependencyOrder now defines traces of complete prerequisite schedules. Two
general lemmas prove that adding prerequisites on the same node set restricts
schedules and their fixed-label trace projections. Five concrete certificates
show that adding A→B to the earlier replacement excludes reverse order, retains
a forward schedule/trace and refines the unconstrained replacement. This is
neither a general node-deletion proof nor value-dependent state/error refinement.
The earlier twelve arbitrary-state/error proofs retain their fixed-schedule scope.

Review packets now attach both fixed-schedule effectful proofs and the source-
linked ordering diagnostic. Validators reject missing, retargeted or promoted
packets. Accepted source proofs remain null. The source census still requires
independent branch/helper/guard review and a final observation contract.

## Validation and burden

`python tools/checkpoint.py` passes all48 tool/evidence tests, Lean builds and
axiom audits, positive probes, negative false-proof controls, and archived
native checks. Adversarial tests reject case/mode omissions, a claimed canonical
repair, broadened execution scope and reversal of the refinement direction.

| Lean category | Previous | Current | Added |
| --- | ---: | ---: | ---: |
| S semantics | 609 | 612 | 3 |
| H shared support | 731 | 751 | 20 |
| R rule proofs | 504 | 504 | 0 |
| A imports/checking | 24 | 24 | 0 |
| C certificates | 218 | 236 | 18 |
| Total | 2086 | 2127 | 41 |

The full development now has48 value rules and69 shared support lemmas. Pure
and effectful graph rules remain separate from value counts; there are seven
original control-order certificates and five diagnostic-repair certificates.
Test/audit sizes are reported separately. The new two generic lemmas and five
certificates use only audited standard axioms. All previous axiom sets remain
unchanged. This measures the resulting artifact, not model-specific effort.

snapshots/boolean-control-family-pilot-v1.zip and
reports/boolean-control-family-clean-replay.json record fresh Lean replay
without Lake caches. Measurements, model probes and prior axiom sets match.
This is same-agent proof replay, not independent source review or fresh native
rebuilding. The complete144 native result rows stay in their separate archive.

The next census step should propagate actual replacement API/control semantics
across source sites and classify their graph obligations. A final source-safe
repair would need a general dependency/observation argument and C++ correspondence;
adding a concrete A→B edge here is only a causal diagnostic. Independent semantic
census/pilot review, remaining operator families, the whole-file campaign and
final verdict are still required.

Fresh Lean snapshot SHA256: 867e68c72af84c6e1a42c8d10a4e573c25e78fc08212f0e14456484357976427.
