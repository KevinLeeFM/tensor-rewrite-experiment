# Independent review of tuple forwarding with observable effect order

**Accept the counterexample in the declared schedule model.** This refutes
post-to-pre refinement for the combined logical-value and relative-order
observation on the stated source-shaped graph pair, since even matching the
order alone is impossible. The previously accepted typed-value theorem still
holds on its original domain. The result belongs to
`HandleGetTupleElement/tuple-projection` (`site-L05566-C009`) and supplies a
negative result for a specific `effect_graph` observation. The other
effect/graph semantics of that record and actual XLA behavior remain open.

## Source interpretation and witness

I checked the unique retained action in `census/site-case-map.json`, its
normalization row, and the `pure_tuple` and `effect_graph` domains in
`census/simple-mathematical-domains-v1.json`. The order witness is a follow-up
to the typed-value review in `../REVIEW.md`. At XLA pin
`e58e523b11f1fde802a493a776d158007486e1bf`,
`algebraic_simplifier.cc:5558–5573` forwards the selected `kTuple` operand.
A coherent source-shaped instance uses a pure scalar constant `x: s32[]`, a
zero-operand effect `A: s32[]`, a tuple `(x,A)`, a scalar GTE at index zero,
an effect `B: s32[]` that consumes the GTE, and root `(A,B)`. Both roots have
the same ordered pair of result shapes. `hlo_instruction.cc:2737–2746`
constructs tuples in operand order. `hlo_verifier.cc:1446–1452,2010–2012,2933–2938`
and `shape_inference.cc:3819–3835` provide the tuple and index checks.
Synchronous scalar custom calls with the side-effect flag give a plausible
interpretation of A and B. `hlo_instruction.cc:2639–2653` recognizes the flag,
and `hlo_verifier.cc:1920–1942,4901–4917` includes layout and specific call
checks. No particular registered callee or executable HLO is asserted here.

Take the GTE and `x` to have identical shapes and layouts, absent sharding,
and no control edges. Then the old-control-predecessor and shape gates in
`algebraic_simplifier.cc:623–634,861–880` fit the witness. The visitor delegates
with control-dependency relay and unused-operand removal enabled
(`dfs_hlo_visitor_with_default.h:384–399`). The computation checks shapes and
sharding, relays explicit edges, replaces uses, and removes dead nodes
(`hlo_computation.cc:2063–2078,2089–2164`). There are no explicit edges to
relay. The pure GTE and the intermediate tuple can become dead. A remains
used by the root, B remains used by the root, and `x` remains used by B.
The removal worklist also checks deadness and skips recursively encountered
side-effecting instructions (`hlo_computation.cc:646–657,710–779`).
The witness concerns loss of ordering, with both effects retained.

The model assumes that each instruction executes once and completes before
its dependents. Every tuple field supplies an explicit data prerequisite
even though the GTE's value depends on only one field. A and B are distinct,
observable, serialized events without implicit token, control, effect-domain,
or backend order constraints. The root depends on both effects and supplies
no order between its operands. The prerequisite assumption matches the
checks in the pinned `hlo_schedule.cc:435–469` for an instruction sequence.
That verifier provides no contract equating all legal sequences with
observable runtime traces. The pinned `operation_semantics.md:90–98`
describes tokens for enforcing order. If the effect contract requires such an
edge between A and B, treats their order as unobservable, or restricts
admissible schedules further, this witness does not refute that contract.
The analogous `ControlOrderCertificates.lean` uses an explicit control edge
in the original And example. Here the path is all data. The And native
diagnostic is precedent for the distinction and gives no execution evidence
for tuple forwarding.

## Exact goal and controls

The frozen proposition quantifies over every legal `post : List (Fin 4)`
and requires a legal `pre : List (Fin 6)` with
`post.idxOf 1 < post.idxOf 2 ↔ pre.idxOf 1 < pre.idxOf 4`. The
fresh check elaborated that literal proposition under negation and accepted
`RevisedBenchmark.TupleProjection.Order.noRefinement` directly at that type.
`Graph.IsSchedule` checks exact length, uniqueness, coverage and strict
ordering of every declared predecessor. `mustOrder` composes three genuine
edges, A → tuple → GTE → B. The post order `[0,2,1,3]` puts B before A
while respecting both dependencies of the root. Thus no original schedule
matches it. Original and rewritten schedules with A before B also pass,
so the finding is that the rewritten trace set allows an additional order.
The terminal proof uses the standard axioms `propext`, `Classical.choice`,
and `Quot.sound` only. The separately replayed typed-value theorem uses
`propext` only.

My fresh scratch harness checked those three schedules as actual
`Graph.IsTrace` values using distinct labels. It rejected a pre schedule
putting A after tuple formation, a post schedule putting the root before A,
and a post schedule putting B before its selected scalar input. A diagnostic
post graph adding A as a direct prerequisite of B accepts the forward order
and rejects the reverse order. A deliberately false positive assertion
that the reverse pre schedule was legal exited 1 with a `decide` failure.
I also compiled the negation of the combined matching condition for arbitrary
Nat-valued readouts on the two schedule sets, by projecting a hypothetical
combined witness onto its order component. This uses no assumptions about
effect output values. It is consistent with choosing fixed values, permitting
the difference to be solely the observed relative order.

## Independent replay

I reviewed the proof and local definition closure
`OrderProof → OrderSpec → TensorRewrite.Pilot.DependencyOrder → Std` from
exact commit `16d800da60b3787375cbf73d497470e4a464bd56`. The preceding freeze
is `f46c888`. Both packet manifests passed against a fresh Git archive,
including the two frozen C++ files and project-local schedule semantics.
The proof SHA-256 is
`ef83a8b7a0605b3aa639ef020a1436f8c0e97eaac197490c7ecec50336570e8d`.
There are no inherited target results in the import closure. The proof and
controls use kernel-checked `decide`, with no `sorry`, `admit`,
`native_decide`, or project axioms.

Using installed Lean 4.35.0, commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc` (x86-64 Linux), I set
`LEAN_PATH` to the archive root, the tuple packet and its order subdirectory.
I ran `lean -o Module.olean Module.lean` from the relevant directory on
`TensorRewrite/Pilot/DependencyOrder`, `TupleSpec`, `TupleProof`,
`OrderSpec`, and `OrderProof`, in that order, followed by
`lean Independent.lean` and the expected rejection `lean Reject.lean`.
The scratch harness and rejection log are in
`/tmp/tuple-order-review.5NSPkY/comparisons/revised-benchmark-20261117/tuple-projection/order/`.
Successful commands took 0.356, 0.349, 0.324, 0.314, 0.357, and 0.480 s.
Expected rejection took 0.318 s, for 2.498 s across Lean invocations. The
first timing wrapper stopped before invoking Lean because `/usr/bin/time`
was absent. Bash's `time` succeeded. Local custom modules were rebuilt from
source. Installed toolchain libraries were reused. No native XLA run,
production backend schedule, complete graph/API contract or C++ correspondence
is claimed.

Review started at 22:01:19 UTC on 2026-11-17. The successful compilation batch
ran at 22:02:49–22:02:52 UTC and the negative control finished at 22:03:18 UTC.
Independent review and reporting wall time was approximately three minutes.
Proof-author effort, active reasoning time, and token/cost measurements are
unavailable to this review.
