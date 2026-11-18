# Independent review: transposed batched nested-dot orientations

**Verdict:** The frozen strict rounded-matrix model is refuted in both orientations. The source-level shape/dimension interpretation and emitted permutation are consistent with the inspected `AssociativeReorderNestedDot` construction. This is not a proof that a particular HLO reaches or executes the rewrite, and it is not native floating-point or backend evidence. Exact source cost admission is conditional on the `GetDotFlops` implementation: the pinned snapshot contains its declaration and the reassociation call, but not its implementation.

## Statement and source mapping

I inspected `BatchSpec.lean`, `BatchProof.lean`, `BatchControls.lean`, `NestedSpec.lean`, `RadixSpec.lean`, `FREEZE.md`, the replay script, and the pinned `algebraic_simplifier.cc` source at the source-hashed lines 3930–4272. The modeled six logical dimension groups are `X,Z,m,k,n,p`. Their per-operand roles are:

| Operand | Original `AB` or `BC` inner dot | Re-associated inner dot |
|---|---|---|
| A `[X,m,k]` | `X` batch, `m` free, `k` contracting | `X` batch with `BC`, `m` free, `k` contracting |
| B `[X,Z,k,n]` | `X` batch, `Z,n` free, `k` contracting in `AB` | `Z` batch, `X,k` free, `n` contracting in `BC` |
| C `[Z,n,p]` | `Z` batch, `p` free, `n` contracting in outer `(AB)C` | `Z` batch, `p` free, `n` contracting in `BC` |

For the lhs-inner orientation, old `(AB)C` emits `[Z,X,m,p]`; new `A(BC)` emits `[X,m,Z,p]`. The old-to-new output-axis map `[2,0,1,3]` used by `toLeft` is correct. For the rhs-inner orientation, old `A(BC)` has `[X,m,Z,p]` and replacement `(AB)C` has `[Z,X,m,p]`; map `[1,2,0,3]` in `toRight` is correct. The dimensions consumed by the outer contraction (`n` for `AB`, `k` for `BC`) are old-inner free dimensions, not old-inner batches. This avoids the source stop condition for a dimension mapped to both inner operands. The source constructs the three pairwise dimension-number sets, re-derives dot maps, then creates and applies the output transpose when nonidentity; the frozen maps match those shapes.

The `HandleDot` path returns early for layout-sensitive mode and for zero-element dot inputs/results; positive dimensions and the explicit layout-insensitive / associative-reordering-enabled assumptions avoid those exits. The source option proto defaults `associative_reordering_threshold` to 2.0; the freeze assumes the flag enabled. This packet's `SHA256SUMS` verifies the frozen simplifier source file, but does not include the options proto or a `GetDotFlops` implementation. In this source snapshot `hlo_cost_analysis.h` declares `GetDotFlops`, while the implementation is absent. The packet formula gives all four dots the common `X*Z` factor and is dimensionally consistent with each dot's batch/free/contract axes; the actual helper's source formula was not independently verified here. Therefore the cost-trigger conclusion is a model calculation, not a complete pinned-source cost audit.

## Counterexamples, arithmetic, and controls

Both instantiations use `X=Z=3`, `m=k=n=p=4,1,4,1` for lhs-inner and `m,k,n,p=1,4,1,4` for rhs-inner. In both, the original rounded nested result at the admitted coordinate is `25165832`, and the permuted replacement is `25165830`.

For lhs-inner, A is constantly 3 at selected `x=1`; B's contracted-row values across `n` are `[2^23,1,1,0]`; selected C is constantly 1. In `(AB)C`, products `3*B[q]` are individually formed, then the `n` accumulation is rounded after each addition: after `2^23*3`, the two additions of 3 round from 25165827 to 25165828 and then from 25165831 to 25165832. In `A(BC)`, the inner sum `2^23+1+1` is exact at that magnitude (where the ulp is 1), and its product by 3 is 25165830, exactly representable at the output magnitude.

For rhs-inner, selected A is constantly 1; B has rows `[2^23,1,1,0]` on its contracted `k` coordinate; selected C is constantly 3. In `A(BC)`, each inner product `B[t]*3` is formed and the outer `k` fold rounds to 25165832. In `(AB)C`, the inner `k` fold computes `2^23+1+1=8388610` exactly, then multiplies by 3 to obtain 25165830. Thus the two orientations each have the direction-specific order and a distinct nonidentity output map.

All initialized inputs are nonnegative exact small integers; every loaded value, rounded product, and intermediate sum is below the `rounded` bound `2^30`, so all compared observations are defined and remain in the finite binary32 range represented by the reused `RadixIota.r32`. The arithmetic is a strict RNE-after-each-primitive model with a fixed increasing fold, not a claim about an XLA backend's reduction order, fused arithmetic, or actual runtime values.

The cost instantiations are also positive: lhs-inner `leftCost=64`, `rightCost=16`, and multiplying by `X*Z=9` gives 576 versus 144 (ratio 4, satisfying the model's strict `>2`). Rhs-inner has `leftCost=16`, `rightCost=64`, hence 144 versus 576 (ratio 4 the other way). The controls check the output-axis selections for both permutations and a small non-triggering cost inequality; they do not provide a separate agreeing numeric-data control.

The existing `nested-dot-round` packet uses the same `left`/`right` arithmetic core and RNE rule, so the new packet reuses that arithmetic and its counterexample pattern. The new work is the batched `X,Z` geometry and the two different nonidentity output maps. Treat this as one packet with two direction-specific model refutations, not two independent proof efforts; source-record/branch reachability remains unresolved.

## Replay and axiom audit

Fresh command: `LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/nested-dot-transposed-batches/replay.py` from the repository root. All five listed source/spec hashes matched. Fresh private-directory Lean 4.35.0 compilation succeeded for `RadixSpec`, `NestedSpec`, `BatchSpec`, `BatchProof`, and `BatchControls`; all exit codes were 0. Compiler times were 0.435, 0.363, 0.357, 0.383, and 0.335 seconds (sum 1.873 s); shell replay wall was 1.919 s. `#print axioms refuted` reported `[propext]`. No `sorry`, `admit`, native evaluation, or project axiom occurs in this closure. The control compilation and replay are recorded in `review.log`.

**Time:** no package setup/download/build was needed. Source reading preceded the first explicitly timestamped replay; that review-start timestamp was not captured, so total reviewer wall/active reasoning time cannot be reconstructed. The replay itself was timestamped 2026-11-18 04:45:58–04:46:00 UTC; the earlier attempt to use unavailable `/usr/bin/time` did not start the replay. Compiler time and replay wall above are measured. No speedup or proof-search-efficiency claim is made.
