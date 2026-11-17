# Actual-plan cast bridge attempt

Bounded attempt at commit `cef2ce9` to instantiate `merged_head_of_tail_packing` on the actual tails. Work is isolated to `ActualCastBridge.lean` and this report. Original frozen goal/source/import files were not edited. The draft is uncompiled and is not a theorem result.

The supplied `ActualMergedHead.lean.txt` has an ill-typed direct target: it applies `preIndex` at the wrong tail rank (`n := rank - moved`) and expects a casted index. I corrected the target shape direction by defining left/right generic tail frames and indices with explicit rank equalities `k+2 = rank+1-moved` and `k+1 = rank-moved`, and inserted `rank_cast_packed` for both sides. A fresh offline Lean 4.35 compilation rebuilt the 37-module closure cleanly through `MergedHeadConnection`; it failed in the candidate module.

Exact remaining blockers in this draft:

1. The rank-cast equalities embedded in the theorem's dependent `let` binders are not discharged by `omega` from the context available in the proposition. They need explicit proof terms from `moved_before_split` and `plan.axes.split.isLt`, carried consistently into the dependent shapes/indices.
2. The attempted theorem conclusion currently states only equality of the two head coordinate values. The helper's actual conclusion is the merged-head equation: right head equals left head times the second left extent plus the second left coordinate. The target must be stated in those terms (using the casted frames), not weakened to simple head equality.
3. Existing suffix shape proof's `simp` step does not reduce the dependent `Fin.cast` frame equality. Thus the helper's `sameSuffix` premise still needs explicit Fin extensionality and axis-value transport; no premise was assumed.

Compiler diagnostics also showed the final `simpa` does not match the intended merged-head equation. No actual-plan equation was proved. No nonempty/one-chunk/zero-shape controls were compiled for this candidate. The generic helper and prior control evidence remain separate and are not revalidated here.

Focused active effort was approximately 7 minutes, including two fresh 37-module closure compilations (~13 seconds each) and direct diagnosis. No downloads or builds outside the pinned Lean closure. Next bounded attempt should first move the dependent cast-rank witnesses out of the proposition into explicit theorem hypotheses/definitions derived from the plan, then write the exact merged equation, and only then repair the suffix cast transport. Time to completion is uncertain; the present attempt did not establish that the bridge is viable. No rewrite or speedup claim.

## Coordinator checkpoint

The uncompilable draft has been preserved as `ActualCastBridge.lean.txt` so it is not mistaken for an accepted Lean module. The preexisting failed draft was not a frozen statement: correcting its local rank and stating the exact merged arithmetic equation is authorized without changing `Goal`. This attempt did not complete that correction or establish its supporting count and cast premises. Both manifests were independently rechecked after the attempt: all 28 original and 45 separate-freeze files matched.

A reasonable next step is one focused pass that first defines the cut ranks and their bounds from `moved_before_split` and `split.isLt`, then states the correctly typed product-plus-coordinate equation and proves suffix transport by `Fin.ext`; it must instantiate the reviewed helper and run the existing pointwise/zero controls. At least those separate steps remain, and there is no reliable completion-time estimate: seven minutes of active work did not reach a compiling candidate. More framework is not established to be necessary, but none of the current candidate counts as proof of the actual-plan gate.
