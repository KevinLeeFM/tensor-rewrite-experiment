# One held-out logical rewrite partition, checked in cloud

One previously unproved terminal mathematical target relative to the inspected repository/paper-case audit is now proved: reversal commutes with an order-preserving reshape that inserts only unit axes, with reversal dimensions correctly remapped and unit axes discarded. The statement quantifies arbitrary ranks, arbitrary natural extents, data types, tensors and legal insertion plans; retained zero and unit extents and scalar ranks are admitted. Credit **one unit-insertion mathematical partition**, not complete XLA branch closure or certified global novelty. The earlier Nat smoke identity is unchanged and is not counted as a novel rewrite.

The source is XLA e58e523b11f1fde802a493a776d158007486e1bf, algebraic_simplifier.cc:7287–7320. Layout-insensitive pure logical interpretation, reshape projection and native axis-list remapping are explicit translation assumptions. The native helper can also recognize zero-sized modified gaps, outside the inserted-unit-only partition. No C++–Lean correspondence, native pass execution/reachability, layout/effects result or complete source-rewrite claim is made.

## Frozen inputs and independent work

Preproof local checkpoint: `a6ea7403e7b65c71e5715d3dd02421ff2685ca5c`, based on validated migration commit `f468e943febf52567b38b4839c1812eeb5f8ae5d`. `frozen-manifest.json` fixes actual Spec, baseline, guard, controls, review and source bytes. They remain unchanged after proof development. The separate original and smoke worktrees remain clean.

An independent candidate/statement reviewer checked source guards, actual definitions and related existing project/paper/fixed-tactics theorem statements. No equivalent terminal target was located. This is a scoped overlap audit, not a semantic decision procedure or global novelty certificate. The clean custom baseline is only copied Tensor and Indexing semantic modules, importing pinned Std; no existing case proof or target-specific helper is imported.

A separate proof worker started with no parent history and received only Spec, Guard and those two baseline files. It supplied one theorem and zero helper lemmas. Workers ran sequentially, with at most coordinator plus one active worker. The coordinator/reviewer have prior project exposure, so the whole trial is not blinded. Independent final review accepts the exact frozen theorem; that reviewer inspected the coordinator's replay rather than independently executing another replay.

## Kernel checks and controls

Fresh offline replay with Lean 4.35.0, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc, passed all twelve success/control subprocesses. Accepted theorem axioms are `[propext, Quot.sound]`. Its elaborated type is definitionally equal to frozen Goal; no premises or guards were narrowed. No sorry/admit/native_decide/new project axiom or historical solution import appears in the accepted proof.

The nonempty witness is [2,3] → [1,2,1,3,1], retained axes [1,3], input x(i,j)=10i+j. Reversing output axis one yields 10 at zero coordinates; a wrong unadjusted input-axis reversal yields 2, and omission yields 0. A separate kernel theorem refutes the well-formed wrong proposition. Its proof trial fails for the intended unequal sides. A real quarantined IndexLemmas import compiles and is then rejected by the environment guard. An existing theorem of the wrong type is rejected by the signature guard. Scalar-to-two-unit-axis and retained-zero [0]→[1,0] plans are explicitly constructed and audited; empty cases do not substitute for nonvacuity.

An independent Python row-major/source-remapping sanity check inspected 187 plans, 2,127 axis masks and 4,675 observations with no mismatch, including scalar/empty shapes. This is source-transcription confidence, not native XLA execution or compiler correspondence.

The proof actually needs only retained-extent agreement; the other plan fields certify the intended logical shape interpretation. Its short coordinate reasoning should not be presented as evidence of generally difficult proof search. Guard/scanner checks are operational controls for this manually reviewed artifact, not a universal adversarial sandbox.

## Time, failures and code burden

| Stage | Observed time |
| --- | ---: |
| Setup/specification/candidate gate, enclosing coordinator interval | 430.032 s |
| Independent actual statement review, overlapping setup | 112.629 s |
| Proof development, including tools/messages and compiles | 125.490 s |
| Compiler subprocesses inside proof development | 2.567 s |
| Failed first final replay, audit-only infrastructure issue | 4.123 s |
| Successful fresh final replay, all checks | 6.255 s |
| Proof module within successful replay | 0.768 s |
| Independent final review, overlapping replay/reporting | 154.085 s |

Enclosing intervals overlap; do not add nested compilation/review times twice. Earlier source-review exact start is unavailable. `timing-ledger.json` records the final coordinator elapsed checkpoint. Earlier official compiler download (154.56 s) and extraction (5.65 s) were completed migration setup, separate from this trial. Model/effort/token quantities are not observable. No matched fixed-tactic comparison was measured for this target; historical replay is not discovery time, and no speedup/productivity comparison is supported.

All failures are retained. Setup required repair of witness tactics/decidability/typing, the initially overbroad guard, its exact generated-name allowlist and malformed first control invocations. Final preproof controls failed only for intended reasons. The first worker compile failed on dependent rewriting and operational guard/command issues; the second passed with unused-simp warnings; the third passed without warnings. The first final replay passed the theorem but exposed a dependent-function typing error in the scalar Audit witness. Only the postproof Audit was corrected; its original source and replay failure are archived. No failed `sorryAx` diagnostics count as accepted proofs.

The existing lexical counter reports 60 new Lean code lines for entire Spec+Proof (27+33), including headers/audit commands; 32 preexisting baseline lines are disclosed separately. Active operational/control sources add 134 lines. Complete Lean source inventory is 275 lines, including 12 copied historical forbidden-control lines and 37 archived failed-Audit lines. Imported Lean/Std code is excluded. No target-specific helper lemma was added.

## Replay and evidence

From a fresh checkout of this branch:

```sh
LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/heldout-unit-reverse-v1/replay.py
python3 comparisons/heldout-unit-reverse-v1/coordinate_checks.py
```

The replay creates a fresh replay-build and refuses to reuse an existing one. Use a fresh checkout for another run. It checks frozen hashes/imports, rebuilds only the two baseline modules plus case/audit files, and runs the three intended-failure controls. No Lake build or dependency download occurs. The final runner/Audit are postproof validation tools, not preregistered inputs.

Evidence: frozen-manifest.json; independent-statement-review.md; independent-final-review.md; proof-development.json; setup-commands.json; cloud-replay.json; replay-failure-1.json; coordinate-checks.json; timing-ledger.json; code-size.json. No remaining mathematical or replay blocker for this partition. Broader helper scope, native correspondence, certified novelty and matched productivity remain unestablished and were not pursued.
