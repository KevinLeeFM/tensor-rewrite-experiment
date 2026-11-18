# Independent review: nested dot with three contraction edges

**Verdict:** `Triangle.verified` proves the frozen exact-`Int` equality for all finite extents, data callbacks, and result coordinates. The fixed nontrivial source-shaped control shows the third AC edge is live and the source's strict cost gate can be met. This is one lhs-inner/direct mathematical case. It does not prove C++/HLO execution or machine-width integer equivalence, and it does not cover the reverse source branch as a separate outcome.

## Three-edge geometry and overlap

I checked the frozen goal, exact definitions, controls, all proof imports, their hashes, and `AssociativeReorderNestedDot` at pinned simplifier lines 3930–4272. The model is `A[M,I,J]`, `B[I,K,N]`, `C[J,K,P]`:

- Old inner `AB` contracts edge I (A axis 1 with B axis 0), yielding `[M,J,K,N]`.
- Old outer `(AB)C` contracts J and K (inner axes `[1,2]` with C axes `[0,1]`), yielding `[M,N,P]`. These are respectively AC and BC edges; both are real simultaneous contractions.
- Reassociated inner `BC` contracts K (B axis 1 with C axis 1), yielding `[I,N,J,P]`.
- Reassociated outer `A(BC)` contracts I and J (A axes `[1,2]` with BC axes `[0,2]`), yielding `[M,N,P]`. These are AB and AC.

The output order is the same on both paths; no batch dimensions or output transpose are modeled. In source, J on the old inner output is mapped only to inner lhs A, K only to inner rhs B. Therefore neither outer-contracted axis is a dimension produced by batching both inner operands, so the source's `from_inner_lhs && from_inner_rhs` stop case does not fire. The code assembles the AC and BC pairwise dnums and then the new AB and AC dnums, matching the frozen index formula.

The proof reduces both sides by distributivity to the same finite sum over `i,j,k`; `exchange` reorders finite axes using the reviewed, reusable `MergeAxes.identity` theorem. The reusable helper is general rectangular finite-sum order exchange, not a triangle-specific result. The historical `GroupedSums.dot_associativity` concerns the ordinary path `A[M,I] B[I,J] C[J,K]`; it has a single chain of two contracted links and no common J/K edge between A and C. The present nontrivial triangle closure is therefore a distinct mathematical geometry. Earlier rounded `NestedDot`/batched cases are also different (two contraction groups and strict RNE values). Count this as one new lhs-direct case, not an additional reverse-orientation case.

## Source guards, cost, and controls

The source path assumes layout-insensitive mode and `use_associative_reordering`; the pinned option proto default threshold is 2.0. Positive control extents avoid the early zero-element rewrite. There are no batch axes, so the inner-batch contraction stop condition is inapplicable. The model's matrix products use exact mathematical integers; finite-width integer wrap, C++ correspondence, native execution, and backend behavior are explicitly outside scope.

The all-nonunit cost witness uses `M=16,I=2,J=3,K=8,N=3,P=2`. Using the pinned `GetDotFlops = 2 * resultElementCount * contractingWidth` formula (independently source-checked in `nested-dot-transposed-batches/SOURCE-SUPPLEMENT.md`), old AB costs 4608 and outer costs 4608, total 9216. New BC costs 576 and outer costs 1152, total 1728. Thus the source ratio is 16/3, strictly above 2. The Lean control checks the equivalent strict inequality.

The asymmetric control uses 2-wide I/J/K, with A and B diagonals and C diagonal values -2 and 5. Both calculations return 3, with contributions from the shared J/K condition. Replacing the AC coordinate by `1-j` makes the replacement return 24, demonstrating that the AC edge is not dead. An empty J contraction returns zero on both paths. The controls also keep the source-shaped cost example nontrivial; the universal theorem itself has no cost or positivity restriction because exact finite-sum equality holds even for empty extents.

## Fresh replay and trust closure

Fresh command: `LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/dot-triangle-contract/replay.py`. All four packet SHA entries matched; the separate `PROOF-IMPORT.sha256` matched `MergeProof.lean`. Lean 4.35.0 freshly compiled `MergeSpec`, `MergeProof`, `TriangleSpec`, `TriangleProof`, and `TriangleControls`, all exit 0. Axiom output for `Triangle.verified` is `[propext, Quot.sound]`, inherited from the finite-list helper. No `sorry`, `admit`, project axiom, or `native_decide` appears in this closure. Replay and compiler times are in `review.log`.

This validates one exact mathematical model and source-shape interpretation. It does not establish that an arbitrary XLA HLO of that signature reaches the branch, that all source guards are exhaustive, or that machine `Dot` computes unbounded Int arithmetic. The source-derived no-batch case and threshold are explicit assumptions of the packet.
