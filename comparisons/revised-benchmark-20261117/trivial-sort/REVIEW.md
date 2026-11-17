# Independent review of the two trivial-sort value questions

**Accept both exact logical-value model results.** The first conjunct of
`RevisedBenchmark.TrivialSort.correct` answers
`HandleSort/trivial-single` (`site-L10266-C014`). The second answers
`HandleSort/trivial-tuple` (`site-L10269-C012`). Coverage is complete for the
declared finite array values and ordered tuples of arrays with common
dimensions. The two records share one proof. This review leaves the source
records open for their dynamic-shape, layout, comparator execution and
graph/effect obligations. No implementation outcome was tested.

## Source interpretation and boundaries

I checked the two entries in `census/scalar-control-cases.json`,
`census/site-case-map.json`, and
`census/scalar-control-mathematical-domains-v1.json`. At pinned XLA
`e58e523b11f1fde802a493a776d158007486e1bf`,
`algebraic_simplifier.cc:10260–10272` applies the disjunction on operand
zero, returns that operand for one input, and constructs a tuple from
the original operands in order for the other branch. `shape_util.cc:804–806`
defines the zero-element test as the presence of any zero axis of an array.
`hlo_verifier.cc:1343–1405` requires at least one operand, checks common
dimensions and comparator parameters and uses variadic shape inference.
`shape_inference.cc:1644–1663` gives the original one-input shape or the
tuple in operand order. `operation_semantics.md:5374–5426` describes
independent fibers, shared selection across the operands, heterogeneous
element types, ordered tuple positions and the stability flag. In
`hlo_evaluator.cc:4414–4450,4534–4541,4627–4668` the evaluator builds
one index ordering per fiber, uses it for every operand and packages the
results by operand count. These files and `shape.h` matched their SHA-256
entries across the repository's main, dependency-supplement, indexing,
reduction and dynamic-index source manifests.

The adopted mathematical assumption is that a logical result of Sort
is a fiber-local reordering, with one common selection for all tuple
components. Both stable and unstable fiber permutations are included:
each supplies a bounded source coordinate for every valid output
coordinate. The model quantifies over even nonbijective selections.
Its guard makes bijectivity, comparator ordering and tie policy
unnecessary for logical value equality. It says nothing about whether
a particular comparator terminates, is called, has effects or executes
with a particular count. The Lean index contains a valid bounded
`axis : Fin r`, as required for the modeled sort. A rank-zero array
has no legal sort axis. The tuple covers all arities at least two,
including mixtures of payload types, using `Fin (k + 2) → Type` to
preserve the component index and its own type. The admitted shape
describes common actual finite extents.

There is a concrete reason to keep the dynamic source boundary open.
`shape.h:185–189` encodes the unbounded dynamic dimension sentinel as
`INT64_MIN`. The raw signed comparison at `algebraic_simplifier.cc:10264`
would be true on that sentinel. Also, `SameDimensions`
(`shape_util.cc:941–949`) skips extent equality when either dimension
is unbounded. Neither observation establishes whether legal unbounded
Sort reaches this pass or what its executable behavior is. The
unbounded sentinel is outside the natural-extent model. The model
also has no representation of declared bounds versus runtime extents,
layout, or graph/API replacement behavior. C++–Lean correspondence
remains outside scope.

## Exact goal, proof and controls

I reviewed the freeze at `94b8ded1858ba83957f70efd79b10715ab273d0b` and
proof commit `700bf9ceccfcf7b6cb18315035ba50f534120dce`. The proof commit
adds only `SortProof.lean` (SHA-256
`fdec790dac479c2ac46b85246f402130b05bd1dda5bae68f5d0ffb0fa0d31e92`).
The packet SHA-256 manifest passed. The complete project-local import
chain is `SortProof → SortSpec → TensorRewrite.Pilot.Tensor → Std`.
The imported project module defines shapes, bounded indices and tensors
as functions on those indices, plus generic constant and map operations.
There is no imported sort result or assumed output equality.

An independent Lean fixture wrote the statement explicitly with
`rearrange` unfolded, proved `Goal = expected` by reflexivity and used
the fully qualified `correct` at that exact type. The proof splits the
guard. A valid output index would provide a member of `Fin 0` on a
zero extent. In the other branch, the picked coordinate and original
coordinate both have values less than an extent at most one, so they
are equal. Coordinates on the other axes are copied by the definition.
Function extensionality proves the single-value result and lifts the
same argument to every component of the ordered dependent family. The
source contains no `sorry`, `admit`, `native_decide`, or project
axioms. Both the main theorem and my exact-target wrapper depend only on
`propext`, `Classical.choice` and `Quot.sound`.

The author's controls passed. My separate fixture applied the theorem
to three distinguishable `Nat`, `Bool` and `Fin 3` components of
shape `[3,1]`. A constant in-fiber selection gave `(3,false,0)` at
the first row and `(5,true,2)` at the last. Picking the first row
instead of preserving the last would change the Nat component. The
fixture also instantiated the empty branch on `[0,4]` with sort axis
one, where the extent-at-most-one condition is false, and separately
on shape `[0]` with sort axis zero. For an unguarded shape `[2]`,
a genuine flip of distinct values changes coordinate zero. Lean
checked the guard fails and proved the inequality by `decide`. The
separate well-typed equality assertion exited 1 with a single
structured diagnostic that `decide` proved the proposition false.

## Replay and review effort

I extracted the three Lean source files directly from `700bf9c` into
`/tmp/tensor-sort-review.71QQQkv8` and verified their identities. From
that directory I ran the following with installed Lean 4.35.0
(`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, x86-64 Linux).
Local modules were freshly built. The installed Lean/Std libraries
were reused. No package fetch, Lake build, or native XLA run occurred.

```sh
export LEAN_PATH="$PWD"
LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean
for module in TensorRewrite/Pilot/Tensor SortSpec SortProof; do
  time timeout 30 "$LEAN" --json -j1 -o "$module.olean" "$module.lean"
done
time timeout 30 "$LEAN" --json -j1 ReviewChecks.lean
time timeout 30 "$LEAN" --json -j1 FalseControl.lean
```

The successful local module commands took 0.371, 0.315 and 0.363 seconds.
The independent exact-type and control fixture took 0.456 seconds.
The expected rejection took 0.383 seconds. Reviewer harness repairs
cost two failed compiler calls (0.436 seconds for non-definitional
numeral bounds and dependent-type inference in the examples, and
0.293 seconds for a globally shadowed `flip` identifier). The initial
timing wrapper exited before Lean because `/usr/bin/time` was absent.
Bash's `time` was used for the recorded commands. Total compiler time
was 2.617 seconds including failed reviewer harness calls. The final
fixtures and JSON negative log are in the stated scratch path.
Their SHA-256 hashes are
`68d81b660211a82193fa8976c4b231d4f30e553063d119c5d4527c720b196903`
and
`91cfe21e84bbcbf23173eca8a44b18557bedcbd9152391e422303faf7c88adde`
respectively.

Measured review started at 22:06:04 UTC on 2026-11-17. The positive
and negative controls were resolved at 22:07:38 UTC, and supplemental
source pins were verified at 22:08:32 UTC. The report was drafted by
22:09:19 UTC, for 3 minutes 15 seconds of measured review wall time.
Active reasoning time,
proof-author effort and token costs are unknown to this review.
