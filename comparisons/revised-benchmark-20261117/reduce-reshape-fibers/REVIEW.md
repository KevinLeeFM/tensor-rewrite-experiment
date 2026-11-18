# Independent review: reduce through reshape fibers

**Verdict: accepted as two complete mathematical model cases under the frozen
common-factor and row-major-fold assumptions.** The proof establishes both
terminal output branches. This is not a proof of the C++ transformation,
`CommonFactors` implementation, rewrite dispatch, or backend reduction order.

## Frozen targets and scope

I reviewed the freeze at `f56dd1dda505618a7bb44aec5065092a20acda2c` and candidate
proof at `deadcb9940246120b3e5bed13a1579efce7ae3ea` (base
`18394ce32f86ff0cab183007fec94e9f26f89c03`). The frozen spec hash is
`44ecb7d49d92f9cae24438b75078d07b11fa3eea2b8ed8a841daba4c1008327d`;
the fresh replay verified it and the other four frozen manifest entries.

The two goals are distinct terminal outcomes from `HandleReduce`:

* `Goal false` / `dropReshape`: dropping the operand reshape preserves the
  exact surviving-axis shape.
* `Goal true` / `moveReshape`: moving the reshape after reduction preserves
  surviving element count, which is the model's final flat-reshape condition.

They share the same normalized shape calculation, per-position projection,
fiber equality, and fold proof. The ledger should count two source branch
outcomes but shared proof effort, not two independent proof developments.

The assumptions are explicit and sufficient for these theorems: legal static
single-array shapes represented by ordered consecutive blocks of equal product;
minor-to-major axis order in the model; paired singleton axes may independently
be kept or reduced; axes in an edited block have a uniform keep/reduce role per
branch; and reductions are deterministic left folds over logical row-major
fibers. There is no reducer associativity, commutativity, identity, or fiber
projection premise. Per-block product equality is a shape condition, not the
desired value equality. Natural-number extents include zero, singleton, and
empty axis lists.

## Proof and controls

The proof computes each group's projection from quotient/remainder and its
product. Equal block products make the kept projection
`k % P + P * outerProjection` agree on both sides; the reduced projection is
the common outer projection. Concatenating the block projections proves
pointwise equality. Filtering the same input range therefore gives identical
ordered fibers, and the arbitrary `foldl` values agree. For `Goal false`, the
result shape lists are equal. For `Goal true`, their products are equal, so
both result lists enumerate the same output positions.

Controls compiled for both goals and include a nontrivial edited block with
kept prefix/suffix axes, a deliberately wrong contiguous-fiber expectation,
an independently checked ordered noncommutative fold, a surviving-axis shape
change for the moved-reshape branch, zero-volume inputs with visible seeds,
rank-zero input, and an empty-side/unit-product block. These are useful
discriminating controls, not a substitute for the universally quantified
proof. The proof imports only `Std` through `FiberSpec`; no project theorem or
target-specific equality is imported. Axiom output for each terminal theorem
is exactly `propext`, `Classical.choice`, and `Quot.sound`; no `sorry`, `admit`,
`native_decide`, or new axiom appears in the reviewed proof.

## Source mapping and boundaries

The pinned `HandleReduce` branches at `algebraic_simplifier.cc:~9260` and
`~9287` match the two modeled outcomes. Branch 1 requires every retained
reshaped axis to be unmodified and constructs a reduction over all original
axes except paired retained axes. Branch 2 requires every reduced axis to be
unmodified (plus the source's dispatch condition) and reshapes the reduction
result. The freeze correctly treats layout-insensitive mode, single-output
dispatch, the option, early returns, and branch order as applicability
conditions outside the two mathematical statements.

The checked source snapshot and hashes establish the caller and
`DimensionsUnmodifiedByReshape` use of `CommonFactors`; the tracked
`util.h:788-797` contract explicitly describes consecutive equal-product
blocks, and `shape_util.cc:1684-1703` filters adjacent 1-by-1 boundaries. The
freeze records a hash and inspection notes for the `CommonFactors`
implementation, including zero-volume behavior. That implementation file is
not present in this worktree, so I did not independently re-open that body.
Accordingly, exact normalization of every source input into the abstract
`Group` descriptor remains the explicitly disclosed source-to-model
translation assumption, rather than a theorem in this packet. This is
consistent with the adopted experiment plan; it limits the verdict to the
model cases.

The model uses an explicit deterministic row-major left fold and therefore
supports arbitrary pure binary operators. It does not establish equivalence
for unspecified/native reduction schedules, floating-point behavior,
physical layouts, dynamic shapes, tuple/multi-output reduction, graph mutation,
or pass reachability. No C++-to-Lean correspondence claim is made.

Overlap is limited: the existing unit-axis reduction rules have different
terms and guards, and `FullSpanWindow.reduce_reshape` compares full-span window
reduction with reduction-plus-output-reshape rather than reducing a reshaped
operand. The two new branch outcomes are therefore not duplicates of those
terminal results.

## Fresh replay and time

Fresh command:

```sh
LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean \
  python3 comparisons/revised-benchmark-20261117/reduce-reshape-fibers/replay.py
```

Result: exit 0; all five frozen manifest entries matched; fresh isolated
compilations passed for `FiberSpec`, `FiberProof`, and `FiberControls` at
0.387 s, 0.375 s, and 0.393 s respectively (1.155 s total reported compiler
wall). Both theorem axiom audits matched the allowed list above. The
independent inspection interval was not instrumented separately; no active
reasoning, token, or monetary cost is inferred. No build or download was run.

This review is independent of the proof authorship but is an evidence/source
review plus fresh targeted Lean execution, not an independent derivation of
the theorem or validation of the C++ implementation.
