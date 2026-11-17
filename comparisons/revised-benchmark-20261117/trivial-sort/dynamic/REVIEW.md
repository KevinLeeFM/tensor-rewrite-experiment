# Independent review of the rank-one dynamic sort model

**Accept both model counterexample certificates at `a107382`.** The one-array
and ordered two-array forwarding propositions are false in the declared
rank-one runtime-length model. **Also accept the separate exact descriptor
classification at `fc47972`.** For each proposition, the universally
quantified guarded equality holds for a descriptor exactly when it is fixed
or bounded. This is a classification of the graph-free model. Source-record
implementation outcomes remain unestablished.

## Source interpretation and runtime boundary

I read project guidance and the frozen packet at
`1429679eeaf84af3e422d92a2076b45148d3ae8c`. Pinned XLA source is
`e58e523b11f1fde802a493a776d158007486e1bf`. The relevant lines are in
the repository's `sources/xla/` snapshot.

- `xla/shape.h:63–66,184–211,218–223,290–292` distinguishes a bounded
  dynamic descriptor from the unbounded sentinel, sets the dynamic bit
  for the latter, and gives the stored extent as signed `int64_t`.
  The Lean value `-(2^63)` is literally `INT64_MIN`.
- `xla/shape_util.cc:804–806` tests for a stored zero extent in an array.
  At rank one, the unbounded sentinel is nonzero. The other disjunct in
  `xla/hlo/transforms/simplifiers/algebraic_simplifier.cc:10260–10272`
  compares the stored extent to one, so it succeeds on the sentinel.
  The handler forwards operand 0 for one input and builds a tuple in
  operand order otherwise.
- `docs/operation_semantics.md:5374–5426` specifies ascending order with
  strict less-than, a shared permutation across arrays, interleaved
  comparator parameters, and tuple order. The pair witness uses a pure
  comparator on the first parameter pair and ignores the Boolean pair.
  Its keys are distinct, so stable and unstable tie policy have no
  bearing. Values 0 and 1 fit an ordinary integer array, and a Boolean
  payload fits a predicate array.
- `xla/service/hlo_verifier.cc:1343–1405,2933–2938` checks the
  comparator's scalar predicate result and two parameters per operand,
  common dimensions, and the inferred result shape. Axis zero is
  in range for rank one. `xla/shape_util.cc:941–949` skips a stored
  extent-equality test when either side is unbounded. The model
  explicitly chooses arrays of equal actual length.
  `xla/service/shape_inference.cc:1649–1664` preserves the shape
  of the sole input or the shapes of all inputs in tuple order.
- Shared `ShapeVerifier::Preprocess` rejects a visited instruction
  whose result shape is unbounded, including a tuple with an unbounded
  leaf, when the supported-unbounded predicate is absent or returns
  false (`hlo_verifier.cc:118–133`, `shape.h:191–194`). The option is
  per instruction (`hlo_verifier.h:102–105,171–173`).
  The ordinary verifier visits computations through that shape visitor
  (`hlo_verifier.cc:5081–5114`), and DFS invokes preprocess before
  opcode dispatch (`xla/hlo/ir/hlo_instruction.cc:5316–5324`).
  The pinned subset provides no predicate configuration establishing
  that this unbounded Sort and its unbounded producers pass a real
  pipeline. An opt-in on Sort alone would not clear the check on
  separately visited producers.
- The setup interprets an unknown descriptor as admitting a
  finite length-two realization at the semantic level. The bounded
  dynamic interpretation is consistent with the documented separation
  of runtime size and static upper bound
  (`docs/operation_semantics.md:5038–5068`). This does not instantiate
  an unbounded runtime HLO program. In particular,
  `xla/hlo/evaluator/hlo_evaluator.cc:4429–4443,4623–4668` reads
  the stored sort extent, even though the ordinary fiber evaluator
  documents the expected shared permutation and output packaging
  through its implementation. That code provides no evidence here
  of substitution of a concrete length for the sentinel.

The strongest supported claim is conditional on the runtime-length
model and its selected comparator and rank. The certificates do not
establish an accepted executable unbounded input, pass ordering or
reachability, a pinned compiler bug, or C++–Lean correspondence. Layout,
effects, tie behavior, other ranks and arbitrary comparators are
outside the exact counterexample propositions. The Nat model also
abstracts from the maximum representable stored finite extent. The
length-two witnesses do not exercise that abstraction. These
counterexamples add a partition per existing source-record identity.
They leave the earlier finite-shape partition intact.

## Exact certificates and independent controls

I compared all eight original manifest inputs against the freeze,
`a107382c3955a1ee514c7679d73ae60b802638a7` and the working bytes.
All matched. The supplemental instruction dispatch, shape inference and
evaluator files matched the SHA-256 and revision URLs in
`sources/dependency-supplement.json`,
`sources/indexing-contract-manifest.json` and
`sources/dynamic-index-contract-manifest.json`, respectively.
`DynamicProof.lean` has SHA-256
`e79863aeee51d4195cfd853131961593e1c6e8597d98285b0cd852f79f6f5e68`.
The local Lean import chain is `DynamicProof → DynamicSpec → Std`.
Source inspection found no placeholders, new axioms, or native proof
evaluation. Independent wrappers assigned both fully qualified
counterexamples the negations of explicitly expanded quantified goals,
including their descriptor admission and signed guard match expressions.
Lean reported exactly `propext`, `Classical.choice` and `Quot.sound` for
both candidate theorems and both exact wrappers.

For unbounded length two, the zero disjunct is false and the signed
at-most-one disjunct is true. The single witness sorts `[1,0]` to
`[0,1]`. Sorting `[(1,true),(0,false)]` yields `[(0,false),(1,true)]`,
changing both projections of the forwarding tuple. The tuple
certificate derives its contradiction from the payload conjunct alone,
which suffices for negating the frozen conjunction. The independent
fixture confirms both projections. Fixed or bounded stored extent two
admits length two but fails the guard. An extent of one fires the guard
but cannot admit length two. As additional discrimination, sorted
length-two input, singleton input and empty input were unchanged.
A well-typed assertion of payload preservation on the counterexample
was independently rejected with structured `Tactic.unsolvedGoals` and
residual `False`.

## Classification recheck

I verified all three classification manifest hashes against
`7509a434f76608b43bd698985acf6c057db55a93`,
`fc47972e4a55c07d669d000212ed637ad2082239` and working bytes.
The proof file's SHA-256 is
`582cac940376cdccc5d1bd75107d5940cec2ffae9c54caef65a541652d4a8f9f`.
Its local imports are `ClassificationSpec` and `DynamicProof`. Both
reach the original frozen `DynamicSpec` and then `Std`. The review
wrapper stated both quantified equivalences directly, without referring
to the `Classification` abbreviation, and type-checked against the
published theorem. Both axiom checks returned the same permitted trio.

For a fixed extent or bounded upper limit greater than one, the
guarded equality is true by an unsatisfiable guard. For finite
descriptors with a firing guard, the admission condition forces actual
length at most one. In this case merge sort leaves the list unchanged
with any Boolean comparator, and projecting either component preserves
that equality. I checked both generic consequences independently and
applied the exact theorem to a bounded-one descriptor with concrete
nonempty input `[4]`. The reverse directions use the separately
checked unbounded refutations and the finite proof, with no new premise.
A separate application of the exact theorem refuted the unbounded
tuple proposition. The classification closes the rank-one descriptor
partition in this model. It supplies no stronger executable guarantee.

## Replay commands and time

I used clean source bytes extracted with `git show REV:PATH` into
`/tmp/tensor-sort-dynamic-review.ueutySvx`. Installed Lean/Std were
reused from Lean 4.35.0, commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, Linux x86-64.
No native XLA run, Lake build or package fetch occurred. In that
scratch directory the commands were:

```sh
export LEAN_PATH="$PWD"
lean_cmd=/workspace/toolchains/lean-4.35.0-linux/bin/lean
for module in DynamicSpec DynamicProof ReviewChecks ClassificationSpec ClassificationProof ClassificationChecks; do
  time timeout 30 "$lean_cmd" --json -j1 -o "$module.olean" "$module.lean"
done
time timeout 30 "$lean_cmd" --json -j1 FalseControl.lean
```

The last command exited 1 as expected. The clean successful calls
took 0.375, 0.344, 0.488, 0.264, 0.374 and 0.390 seconds in that
order. The final negative check took 0.459 seconds. Reviewer harness
overhead was a 0.425-second failed run (`decide` could not unfold the
model predicates or merge sort), plus an intermediate run with unused
simplification argument warnings and a repeated negative check
(0.464 and 0.401 seconds). Replacing those tactics with explicit
simplifications fixed the fixture without changing any tested claim.
The fixture hashes for `ReviewChecks`, `FalseControl` and
`ClassificationChecks`, respectively, are
`52f89b791df68e9fa6644e00187a7008c1f449bfea1fe60362fa60387f8159b5`,
`0b0f936dcf173356e712f79dc6b48c37ac9137d420455c90b8b47e3d0f61ff09`
and
`053bd6d5fe3153657d5b92925359e293043b75bb502c2c34cb582bbe16f71fc6`.

Observed initial source/certificate review began at 22:11:07 UTC on
2026-11-17. The first candidate and negative-control pass preceded the
classification read at 22:12:23 UTC. Supplemental source pins and the
clean classification replay were confirmed at 22:12:48 UTC. Exact
manifest rechecks and the clean negative replay followed at 22:13:04
UTC. The initial review interval to the classification handoff was
1 minute 16 seconds. The classification read through clean replay
took 25 seconds. Report drafting finished at 22:14:02 UTC, for
2 minutes 55 seconds of overall wall time. Source review, fixture
repair and the classification allocation partly overlapped. Reasoning-only time, author effort and token costs
were not measured.
