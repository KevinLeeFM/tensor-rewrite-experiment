# Independent review: transposed batched nested-dot orientations

**Verdict:** The frozen strict rounded-matrix model is refuted in both orientations. The source-level shape/dimension interpretation, emitted permutation, and modeled cost ratio are consistent with the pinned `AssociativeReorderNestedDot` construction. This is not a proof that a particular HLO reaches or executes the rewrite, and it is not native floating-point or backend evidence.

## Statement and source mapping

I inspected `BatchSpec.lean`, `BatchProof.lean`, `BatchControls.lean`, `NestedSpec.lean`, `RadixSpec.lean`, `FREEZE.md`, the replay script, and the pinned `algebraic_simplifier.cc` source at the source-hashed lines 3930–4272. The modeled six logical dimension groups are `X,Z,m,k,n,p`. Their per-operand roles are:

| Operand | Original `AB` or `BC` inner dot | Re-associated inner dot |
|---|---|---|
| A `[X,m,k]` | `X` batch, `m` free, `k` contracting | `X` batch with `BC`, `m` free, `k` contracting |
| B `[X,Z,k,n]` | `X` batch, `Z,n` free, `k` contracting in `AB` | `Z` batch, `X,k` free, `n` contracting in `BC` |
| C `[Z,n,p]` | `Z` batch, `p` free, `n` contracting in outer `(AB)C` | `Z` batch, `p` free, `n` contracting in `BC` |

For the lhs-inner orientation, old `(AB)C` emits `[Z,X,m,p]`; new `A(BC)` emits `[X,m,Z,p]`. The old-to-new output-axis map `[2,0,1,3]` used by `toLeft` is correct. For the rhs-inner orientation, old `A(BC)` has `[X,m,Z,p]` and replacement `(AB)C` has `[Z,X,m,p]`; map `[1,2,0,3]` in `toRight` is correct. The dimensions consumed by the outer contraction (`n` for `AB`, `k` for `BC`) are old-inner free dimensions, not old-inner batches. This avoids the source stop condition for a dimension mapped to both inner operands. The source constructs the three pairwise dimension-number sets, re-derives dot maps, then creates and applies the output transpose when nonidentity; the frozen maps match those shapes.

The `HandleDot` path returns early for layout-sensitive mode and for zero-element dot inputs/results; positive dimensions and the explicit layout-insensitive / associative-reordering-enabled assumptions avoid those exits. The source option proto defaults `associative_reordering_threshold` to 2.0; the freeze assumes the flag enabled. An independent official-source supplement checked the `GetDotFlops` formula directly (below): its result-volume and contracting-width computation confirms all four modeled `X*Z`-scaled costs. The packet's own SHA manifest hashes the simplifier source file; the separately fetched cost-analysis source identities are recorded below.

## Counterexamples, arithmetic, and controls

Both instantiations use `X=Z=3`, `m=k=n=p=4,1,4,1` for lhs-inner and `m,k,n,p=1,4,1,4` for rhs-inner. In both, the original rounded nested result at the admitted coordinate is `25165832`, and the permuted replacement is `25165830`.

For lhs-inner, A is constantly 3 at selected `x=1`; B's contracted-row values across `n` are `[2^23,1,1,0]`; selected C is constantly 1. In `(AB)C`, products `3*B[q]` are individually formed, then the `n` accumulation is rounded after each addition: after `2^23*3`, the two additions of 3 round from 25165827 to 25165828 and then from 25165831 to 25165832. In `A(BC)`, the inner sum `2^23+1+1` is exact at that magnitude (where the ulp is 1), and its product by 3 is 25165830, exactly representable at the output magnitude.

For rhs-inner, selected A is constantly 1; B has rows `[2^23,1,1,0]` on its contracted `k` coordinate; selected C is constantly 3. In `A(BC)`, each inner product `B[t]*3` is formed and the outer `k` fold rounds to 25165832. In `(AB)C`, the inner `k` fold computes `2^23+1+1=8388610` exactly, then multiplies by 3 to obtain 25165830. Thus the two orientations each have the direction-specific order and a distinct nonidentity output map.

All initialized inputs are nonnegative exact small integers; every loaded value, rounded product, and intermediate sum is below the `rounded` bound `2^30`, so all compared observations are defined and remain in the finite binary32 range represented by the reused `RadixIota.r32`. The arithmetic is a strict RNE-after-each-primitive model with a fixed increasing fold, not a claim about an XLA backend's reduction order, fused arithmetic, or actual runtime values.

The cost instantiations are also positive: lhs-inner `leftCost=64`, `rightCost=16`, and multiplying by `X*Z=9` gives 576 versus 144 (ratio 4, satisfying the source's strict `>2`). Rhs-inner has `leftCost=16`, `rightCost=64`, hence 144 versus 576 (ratio 4 the other way). The controls check the output-axis selections for both permutations and a small non-triggering cost inequality; they do not provide a separate agreeing numeric-data control.

The existing `nested-dot-round` packet uses the same `left`/`right` arithmetic core and RNE rule, so the new packet reuses that arithmetic and its counterexample pattern. The new work is the batched `X,Z` geometry and the two different nonidentity output maps. Treat this as one packet with two direction-specific model refutations, not two independent proof efforts; source-record/branch reachability remains unresolved.

## Official cost-helper supplement

I independently fetched the pinned official implementation: [openxla/xla `hlo_cost_analysis.cc` at `e58e523b`, lines 484–494](https://github.com/openxla/xla/blob/e58e523b/xla/service/hlo_cost_analysis.cc#L484-L494), blob `edf6656a3d795698200b798249ed940b25ffedb6`; and [the matching header at lines 641–683](https://github.com/openxla/xla/blob/e58e523b/xla/service/hlo_cost_analysis.h#L641-L683), blob `452b18a74dae22991de7e767f82f11592cf0f065`. The implementation multiplies `kFmaFlops` by `ShapeUtil::ElementsIn(result_shape)` and by the product of lhs contracting extents; the header sets `kFmaFlops=2`. Each result volume includes its batch and free axes. Substitution gives `2*X*Z*m*k*n` and `2*X*Z*m*n*p` for `(AB)C`, versus `2*X*Z*k*n*p` and `2*X*Z*m*k*p` for `A(BC)`; the rhs-oriented old/new costs use these latter/first pairs in the opposite order. This confirms the ratio-four witnesses pass the source's `old_flops / double(new_flops) > 2.0` check when the frozen option is enabled. It does not establish that a concrete HLO with the frozen dnums is produced or reaches the source branch.

## Replay and axiom audit

Fresh command: `LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 comparisons/revised-benchmark-20261117/nested-dot-transposed-batches/replay.py` from the repository root. All five listed source/spec hashes matched. Fresh private-directory Lean 4.35.0 compilation succeeded for `RadixSpec`, `NestedSpec`, `BatchSpec`, `BatchProof`, and `BatchControls`; all exit codes were 0. Compiler times were 0.435, 0.363, 0.357, 0.383, and 0.335 seconds (sum 1.873 s); shell replay wall was 1.919 s. `#print axioms refuted` reported `[propext]`. No `sorry`, `admit`, native evaluation, or project axiom occurs in this closure. The control compilation and replay are recorded in `review.log`.

**Time:** no package setup/download/build was needed. Source reading preceded the first explicitly timestamped replay; that review-start timestamp was not captured, so total reviewer wall/active reasoning time cannot be reconstructed. The replay itself was timestamped 2026-11-18 04:45:58–04:46:00 UTC; the earlier attempt to use unavailable `/usr/bin/time` did not start the replay. Compiler time and replay wall above are measured. No speedup or proof-search-efficiency claim is made.
