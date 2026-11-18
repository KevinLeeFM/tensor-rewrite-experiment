# Independent review: merged two-axis reductions

**Verdict: accepted for the frozen exact-Int, single-output reduction model.** The Lean theorem verifies the source's two rank-three axis-removal orders, the lifted/sorted merged dimensions `[0,1]`, and the exact initializer correction. With the legitimate additive identity seed zero, the nested reductions equal the single merged reduction for every rectangular extent and retained coordinate. With arbitrary mathematical seed `c`, the model correctly does **not** claim equality: the original result is the merged result plus the number of inner fibers times `c`.

## Source mapping and axis relabeling

I inspected the frozen files, pinned `algebraic_simplifier.cc`, and the hash-pinned historical `GroupedSums.lean`. `MergeReduces` copies/sorts the inner reduction axes and the outer reduction's axes (`algebraic_simplifier.cc:9014–9024`). It lifts each outer axis from the inner result back to the original input rank by incrementing it once for each removed inner axis not above it (`:9024–9032`), then merges the two sorted axis lists (`:9033–9041`).

In the packet's rank-three shape `[m,n,keep]`, when the inner reduction removes original axis 0, the outer reduction removes shortened axis 0; lifting turns it into original axis 1, so the merged dimensions are `[0,1]`. When the inner reduction removes original axis 1, the outer shortened axis 0 is already below it and remains 0; merging again gives `[0,1]`. `mergedDims` and its proof explicitly cover both cases. The `flat` lemma connects the one merged row-major `(i,j)` enumeration to the original nested fiber sum; `transpose` justifies switching the two exact-Int summation orders when the first reduction removes axis 0.

The source dispatch at `HandleReduce` reaches `MergeReduces` only after earlier branches are inapplicable. In particular, `ShouldBroadcastReduce` short-circuits when the nested argument or result has zero elements (`:9057–9059`; predicate `:8850–8878`); the equal-element-count reshape rule occurs earlier (`:9081–9091`); layout-sensitive mode returns before later reductions (`:9093–9095`); tuple reductions generally return before the merge check (`:9144–9148`); and a transpose-fed reduction may be handled first (`:9150–9196`). The actual merge test then requires the outer init to be identical to the inner init and the two reduction computations to be equivalent (`:9198–9205`). The frozen mathematical formula extends over empty/singleton extents, but those values do not establish that this specific source branch is dispatched for such shapes. Nontrivial `m=2,n=3` avoids the empty and equal-element-count early cases, and the model is single-output/layout-insensitive.

## Initializer distinction and historical overlap

For the first order, the model's original formula is `c + Σⱼ(c + Σᵢ xᵢⱼ)`, while the merged formula is `c + Σᵢⱼ xᵢⱼ`; the difference is `n*c`. In the other order the difference is `m*c`. `Goal` proves these equations over arbitrary `Int` tensors and seeds. `identity` specializes to `c=0`, giving full equality for every `m,n,keep,x,k`, including empty extents. This is the correct acceptance condition for the additive identity case. The source code's merge guard checks matching initializer and reducer but does not itself check that the seed is zero; this review does not elevate the nonidentity mathematical counterexample to a source defect or claim that nonidentity seeds are legitimate benchmark inputs.

The nonidentity controls make the correction concrete: for data `10*i+j`, `m=2,n=3,k=0,c=2`, the first order gives 44 versus merged 38 (`n*c=6`); the reverse order gives 42 versus 38 (`m*c=4`). The zero-row example likewise follows the formula, but the source's early empty reduction path may bypass `MergeReduces`.

The historical `TensorRewrite.PaperComparison.GroupedSums.reduce_nested` is the already established value-level grouped-sum law without repeated initializers. This packet's fresh proof does not import it; it checks its hash and independently spells out the source axis restoration, row-major flattening, reverse-order sum step, and initializer multiplicity. Thus this is a narrow source-axis adapter/correction, not a claim of newly discovering generic double-sum reassociation. There is no floating-point, reduction-order, implementation, or native claim.

## Fresh replay and controls

Fresh targeted replay:

```sh
LEAN=/workspace/toolchains/lean-4.35.0-linux/bin/lean python3 replay.py
```

It passed on 2026-11-18 with Lean 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The model, freeze, source, and historical grouped-sums hashes verified. Fresh temporary compilation times were `MergeSpec` 0.434 s, `MergeProof` 0.348 s, and `MergeControls` 0.313 s (1.095 s summed compiler time; about 1.3 s total replay wall). The terminal theorems report only `[propext, Quot.sound]`. Inspection found no `sorry`, `admit`, `native_decide`, or project axiom in the current packet. The retained `failed-flat.log` records an earlier unsuccessful attempt (`List.sum_replicate` unavailable and unsolved goals, including `sorryAx` in that failed compilation); it is excluded from the successful current proof and replay.

## Timing

Review began at 2026-11-18 03:13:31 UTC. The fresh replay started at 03:14:54 UTC and took about 1.3 s wall (1.095 s summed Lean compiler time). Source/statement/control inspection and report preparation completed at 03:16:13 UTC, for 2 min 42 s total elapsed. No dependency setup, network operation, worker, native test, or broad build was run. Active reasoning time and token usage were not measured.
