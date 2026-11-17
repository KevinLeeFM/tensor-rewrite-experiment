# Space-depth split strategy review

**Verdict: a distinct, bounded decomposition is plausible; it is not yet a proof.** The overall exit gate remains the original frozen `Heldout.SpaceDepthCandidate.Goal`: equality of original and replacement tensors for all admitted Conditions/input, not a helper count. The accepted moved-axis, suffix, packed-position and replacement extraction components remain accepted at their recorded revisions. The split factor, split-axis, other-axis, full-index and original theorem remain unresolved. The outer-rank restriction is a model restriction, not a source invariant; empty output-index cases are vacuous; C++ correspondence is outside scope.

## Exact first gate and why it differs

`SplitStrategyTarget.lean` elaborates the following proposed first falsifiable obligation, without a proof or new hypothesis. For any original frozen `Conditions plan` and `out : Index outer`, let

```
q := Tensor.transposeIndex plan.axes.permutation
       (transpose_extents inner plan.axes.permutation) (originalOuterIndex plan out)
```

Then show

```
(originalIndex plan out plan.axes.split).val =
  (q plan.axes.split.castSucc).val * plan.width + (q plan.axes.split.succ).val
```

This intermediate is a source-specific original-reshape statement, not the frozen `ActualSplitFactorGoal.Goal`. Its first concrete success gate would be a Lean proof of exactly `Heldout.SplitStrategyTarget.Goal`, instantiated into the frozen split factor in the same bounded attempt. It does not assume a nonzero extent: whenever an `Index`/`Fin` coordinate exists its own bound supplies the needed positivity; empty output domains supply no `out`. The target elaborated, but has not been independently statement-reviewed or proved. Before proof work, freeze its full dependency closure and get any required statement review; no current checkpoint expands the proof contract.

Unlike the failed cast-normalization attempts, this route first uses the **row-major semantic decomposition**: prefix | count | width | suffix in `inner`, versus prefix | `(count*width)` | suffix in `shape`. `Conditions.prefixAxes`, `suffixAxes`, `innerCountAxis`, `innerWidthAxis` and `splitProduct` provide the exact extent equations. Split the packed position around the count/width axes, reassociate the finite products, and use the inverse of packing to recover the split coordinate as `countCoordinate * width + widthCoordinate`. Handle the intervening axes in the transposed frame by mapping q through the checked permutation, rather than assuming those axes disappear. The prior worker never compiled this original-reshape coordinate equation; the new target makes that gap explicit, not just a different tactic for the same cast expression. It still may require hard dependent casts, and the examples do not establish it universally.

## Existing facts and direct application

- `Heldout.RecursiveShapeSplit.full_count_split {m n} (shape : Shape (n+m))` gives `elementCount shape = elementCount (preShape shape) * elementCount (tailShape shape)`; `full_linearize_split (index : Index shape)` gives the numeric packed index as `join (linearize prefix (preIndex index)) (linearize tail (tailIndex index))`.
- `Heldout.ContextAssociation.shape_context_associate` equates packed `join pre (join (join x y) post)` with `join pre (join x (join y post))`, after the explicit `Nat.mul_assoc` cast, for arbitrary prefix/suffix shapes and `x : Fin a`, `y : Fin b`.
- `TensorRewrite.Pilot.LinearIndex.delinearize_linearize shape index` recovers the index; `linearize_delinearize shape position` recovers the bounded position. `FiniteProduct.row_join`, `column_join`, and `join_row_column` recover/reassemble packed components. `Heldout.WorkerIndexJoin.packed_component_values` recovers row/column values when both extents and packed values agree. These statements do not on their own prove matching axis/shape hypotheses.
- `Heldout.PermutationCoordinate.count_coordinate` maps q at `split.castSucc` to the original outer coordinate at moved; `width_inverse` fixes `split.succ`. `Heldout.ActualTransportProof.Goal_proved` gives actual concat position = outer moved * moved extent + outer moved+1; `TailHeadConnection.selected_chunk_coordinate` gives row = position / moved extent and column = position % moved extent. Use the actual bounded coordinate and `OrderedSlices.segment_quotient_remainder` to obtain the selected row, not a new positivity assumption.
- The accepted `ActualSuffixProof.Goal_proved` compares all tail coordinate **values** after the two-head/one-head cut; it is a candidate for relating the outer `split.succ` width coordinate to the actual replacement split-local coordinate, but the required axis/cast instantiation is not yet compiled. With that and the row relation, the first gate yields frozen `ActualSplitFactorGoal.Goal`. `OrderedSlices.sourceIndex_split_value` states source coordinate = interval start + destination local coordinate; `ChunkIntervals.interval` gives start `row * width`, and frame distinctness is needed to show the local coordinate is preserved. That adapter is also uncompiled. Both must be compiled to close `RemainingAxisGoals.Split`.
- Split plus the accepted moved-axis theorem still leaves `RemainingAxisGoals.Other`. For those axes one must separately extract input coordinates through the rank-changing reshape and map prefix/intermediate/suffix regions using permutation and frame-rest facts. Only after all other axes compile can the exact `ActualFullIndexGoal.Goal` and then original `Goal` follow by function extensionality and `read_equal_of_index_equal`. No equality of the whole graph follows from this first gate alone.

## Concrete discrimination and limits

`SplitStrategyControls.lean` uses kernel `decide`, not `native_decide`. It defines two fully admitted `Conditions` plans: the earlier rejected candidate (rank 3, count=2, width=2, shape `[2,2,4]`) and a distinct rank-4 plan (count=2, width=3, shape `[3,4,6,2]`, inner `[3,4,2,3,2]`, outer `[6,4,3,2]`). The rank-4 plan has nontrivial prefix, moved, split and suffix dimensions. Six concrete rank-4 output coordinates satisfy the exact factor equation, including positions 3 and 4, separately checked to select row 0 and row 1 across the chunk boundary; five of those also satisfy the proposed original-side first gate. The rank-3 rejected witness's exact factor equation also holds. These are finite, solution-informed checks of two plans, not a proof, reachability claim or exhaustive test; they do not remove valid zero cases.

Checks used existing cached local Lean closure, not a fresh independent replay. The final control compile at 19:31:46 UTC passed in 0.663 s; target statement elaboration at 19:32:30 passed in 0.347 s. Earlier: the initial control check at 19:29:44 failed in 0.632 s because `check` needed unfolding; it passed after correction at 19:30:00 in 0.471 s. A `#eval` inspection at 19:30:20 failed in 0.480 s because the imported module lacked native interpreter code; replacing it with kernel `#reduce` passed in 0.518 s at 19:30:28. Boundary checks passed in 0.536 s at 19:30:54; adding the rank-3 instance passed in 0.592 s at 19:31:28. There were no downloads, broad builds or `native_decide`.

## Quarantine and integrity

The 77-input split-factor manifest hash-check passed with no mismatches. A textual scan of its `.lean` inputs found no `sorry`, `admit`, `native_decide`, or `axiom`/`opaque` declarations; this scan is not a substitute for a transitive axiom audit. A scan of retained packet `.lean`, `.lean.txt` and `.log.txt` found `sorryAx` only in `actual-full-index-residual.log.txt`, which is the output of a **failed** earlier elaboration, not an accepted theorem. The previously prohibited temporary `sorry` scaffold was removed; its existence is preserved in `split-factor-gate-review.md`. Failed drafts remain `.lean.txt` with diagnostics `.log.txt` and are not proof modules; nothing was deleted or counted as proved. Accepted component reviews recorded only the permitted axiom set, but this read-only pass did not independently re-audit every transitive axiom or rebuild their dependencies.

## Bounded decision

A defensible future allocation is one author, no recursive workers, at most 20 minutes for the exact first gate and immediate factor/Split integration, with a ten-minute check for a compiled actual-plan decomposition or a strictly smaller typed residual. Stop if it requires a general new indexing framework, repeated unproductive cast retries, changed assumptions, or an unconnected helper. If the first gate closes but factor/Split do not, preserve the exact residual and seek independent review rather than counting a rewrite. Follow with a fresh sequential review/replay and controls only on a compiled candidate. No reliable completion estimate or comparable speedup baseline exists.

This inspection started 2026-11-17 19:29:00 UTC. New information: a fully typed proposed original-side gate, two admitted model shapes with explicit boundary checks, and a bounded mapping to the split/whole-index obligations. Repeated work: reading previously accepted component and failed-draft evidence, and confirming the already reported rejected instance. The check timings above are observed compiler wall time; active work, blocked/idle time and token costs were not separately measured. No proof worker was launched and no rewrite theorem was proved.
