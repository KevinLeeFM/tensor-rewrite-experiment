# Independent review: transpose to reshape across unit axes

**Verdict: accept the frozen arbitrary-rank logical value theorem.** The sorted-filter criterion is exactly the source predicate under the transpose dimension convention, and the proof establishes equality of row-major ordinals rather than assuming it. The source comment says “more than one” degenerate dimension is permuted, but the implementation guard only requires at least one output extent equal to one.

## Identity, hashes, and fresh replay

Reviewed in `/workspace/tensor-benchmark-orchestration-20261117` at source XLA commit `e58e523b11f1fde802a493a776d158007486e1bf`; packet commits are freeze `077d51d` and proof/control `cdc9c28`. `SHA256SUMS` passed for `FREEZE.md`, `UnitOrderSpec.lean`, and pinned `algebraic_simplifier.cc`.

Fresh command: `LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/transpose-degenerate-reshape/replay.py`, 2026-11-18 04:20:56–04:20:57 UTC (shell elapsed 1 s). All three Std-only invocations returned 0: `UnitOrderSpec` 0.393 s, `UnitOrderProof` 0.334 s, `UnitOrderControls` 0.327 s (compiler-time sum 1.054 s). The replay printed `verified : Goal`; its axiom list is `[propext, Classical.choice, Quot.sound]`. The replay closure has no Lake/package imports, `sorryAx`, `native_decide`, or project axiom. Source-review start was not instrumented; replay command timing is exact, and no other builds/tests were run.

## Source criterion and proof

The helper at `sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc:10305–10317` iterates output axis index `i`. When `shape.dimensions(i) != 1`, it appends `perm[i]`; otherwise it increments `degenerate_count`. It returns `degenerate_count > 0 && absl::c_is_sorted(new_permutation)`. `absl::c_is_sorted` is nondecreasing order, modeled by `(visible size perm).Pairwise (· ≤ ·)`. At the call site `:10573–10576`, a successful test replaces the transpose with `Reshape(transpose->shape(), transpose->operand(0))`. This is not gated by `is_layout_sensitive` at this branch.

For a valid transpose, output axis `j` has extent `inputExtent[perm[j]]` and its coordinate digit is the digit named by that input axis. `ordinal size digit perm` is the row-major output slot read by the replacement reshape; `ordinal size digit (List.range rank)` is the input slot read by the old transpose. `strip` removes every extent-one axis from either fold because the bounded digit is zero and multiplication by one is neutral. The sorted guard plus the legal permutation premise make the remaining non-unit axis lists equal. The proof therefore derives equality of the two ordinals and applies it to arbitrary stored data. It does not assume the desired ordinal equality.

## Rank, zero extents, and controls

The theorem quantifies arbitrary `rank`, extents, and a permutation of `List.range rank`; there is no positive-rank premise. Rank zero and all-unit nonempty shapes satisfy the ordinal identity. With any zero extent, a valid coordinate cannot exist because `digit i < 0` is impossible; the bounds premise makes the coordinate theorem vacuous, as required for an empty tensor. The source guard may still fire on a zero-element shape if another output dimension is one and the filtered permutation is sorted; no value coordinate then exists. The packet proves logical values only; it does not model physical layout, memory transfer, aliasing, bit reinterpretation, or source execution.

Controls cover a nontrivial rank-three permutation with a unit axis interposed (`visible=[0,2]`, both ordinals `3`), a reversed non-unit-axis order with unequal ordinals, filtered-axis order, all-unit axes, and impossibility of a bounded coordinate when one extent is zero. These are targeted examples, while the theorem supplies arbitrary-rank generality.

## Boundary

The source predicate examines output extents and permutation entries, not input-axis numeric order directly; the proof's `size`-indexed `visible` list is correct because `outSize[j]=inSize[perm[j]]`. HLO's legal transpose shape/permutation relation is a prerequisite from the source operator, represented by `perm.Perm (List.range rank)`. No independent C++/Lean correspondence, source execution, layout behavior, or performance result is established.
