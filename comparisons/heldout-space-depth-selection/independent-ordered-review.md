# Independent review: ordered-slice prerequisite

**Disposition: accepted as generic ordered-block support, with bounded control and scope caveats.** The lemmas establish list-order concatenation facts for arbitrary legal intervals of one shared width. They do not enumerate the source rewrite's chunk intervals, state its exact source guards, prove either reshape/transpose coordinate map, or prove the proposed rewrite. The next bounded source-enumeration step is justified; rewrite-proof work is not yet justified by this prerequisite alone.

## Checkpoint and inspected closure

- Repository `/workspace/tensor-heldout-chunk-20261117`, exact `HEAD` `1fdfdeade61a642552d18ade928fb50e94b0d2ee`; initial and final worktree status clean except this review file.
- Read `AGENTS.md` and required repo context (`README.md`, `docs/theory-scope.md`, `docs/dependencies.md`, `docs/experiment-plan.md`), plus `ORDERED-SLICES-REPORT.md`, `OrderedSlices.lean`, `OrderedSlicesTests.lean`, `replay_ordered.py`, `SliceTransport.lean`, `independent-transport-review.md`, and `STATEMENT-DRAFT.md`.
- Audited the complete newly added direct import `TensorRewrite/Theory/ConcatenationLemmas.lean` and its import closure. Its only project import is `TensorRewrite.Theory.Concatenation`, whose only project import is `TensorRewrite.Pilot.Tensor`; that module imports `Std`. The path therefore closes at generic Std tensor/shape and arbitrary-axis concatenation definitions. `ConcatenationLemmas` provides generic frame-coordinate replacement, concatenation segment selection, packing/flattening and slice transport lemmas. I found no target-specific space-depth equality or desired rewrite proposition in this closure. The new import does enlarge the proposed proof baseline and must be included in any later hash/allowlist audit.

## Theorem and control findings

`Interval extent length` carries exactly the local legality fact `start + length ≤ extent`. `blocks` maps each interval in caller-provided list order to the actual `sliceBlock`, so list order is preserved by construction. The list is not required to be sorted, contiguous or gap-free; this is a useful genericity property, not a source fact.

`blocks_total` gives `intervals.length * source.shape length axis`, and `output_shape_axis` derives the exact shape on the concatenation axis and unchanged extents elsewhere. `select_block` requires an explicit decomposition `leading ++ chosen :: trailing`, then uses `readAt_middle` to select the chosen list entry at `total leading + coordinate`. `select_source` reduces that chosen block to an input read at `sourceIndex`; `sourceIndex_split_value` exposes the actual source-axis coordinate as `interval.start + local`. `sourceIndex_chunk_value` only specializes this under the explicit premise `interval.start = chunk * length`. The quotient/remainder lemma is for an already bounded local coordinate, so it correctly entails positive `blockExtent`; it does not manufacture a source chunk decomposition.

These statements preserve actual operand order and coordinate selection without assuming equality between final tensors. They cover arbitrary finite rank with a selected `Fin rank` axis, and arbitrary `α : Type`. Rank zero is excluded by the need to supply an axis. Empty interval lists have total extent zero and no concat-axis index. For zero-width slices, the retained source split axis has extent zero, so the tensor index domain is empty even when the distinct concat axis has positive extent (as in the test frame, where each zero-width block still has concat extent 3). Separately, a zero concat-axis extent gives no coordinate along the concatenation axis. Neither case invents a tensor value. The concrete tests include empty lists, zero-width intervals, an unrelated zero extent, segment boundary values 2/20, and wrong-axis output 10 versus 20 at matching row-major flat position 3. The wrong-axis case is a well-typed finite diagnostic, not a general wrong-rewrite theorem or source execution.

No issues found in the listed theorems' interval order or selected source-coordinate calculation. A later source-specific lemma still needs to construct the list `[⟨i*c, ...⟩ | i < k]`, discharge every interval bound from the split product, establish increasing/contiguous starts, and connect the source's loop index and concatenate axis to this generic list. None of those facts is present here.

The outer-rank requirement `m ≥ n` in `STATEMENT-DRAFT.md` remains explicitly a **model restriction** to make the draft's unchecked indexing well formed; it is not proved by these generic lemmas and must not be described as an XLA source invariant. Likewise, translation of the source branch, mathematical-integer/no-overflow profile and operator interpretation remain assumptions described by the draft, not results of this helper review.

## Fresh offline replay and axioms

Freshly rebuilt, in a new `/tmp` import directory, the six modules in the replay closure with `/workspace/toolchains/lean-4.35.0-linux/bin/lean` 4.35.0, commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`: `Tensor.lean`, `Concatenation.lean`, `ConcatenationLemmas.lean`, `SliceTransport.lean`, `OrderedSlices.lean`, and `OrderedSlicesTests.lean`. All six commands succeeded. I did not invoke the checked-in replay script because it writes `ordered-replay.json` into the case directory; no tracked receipt was overwritten.

The eight ordered-slice theorem axiom outputs were all `[propext, Quot.sound]`. Slice transport outputs were `[propext, Quot.sound]` except `destination_extent_of_distinct`, which was `[propext]`. No `sorryAx` appeared; source scans of the inspected modules show no `sorry`, `admit`, `native_decide`, or project axiom declarations. Standard Lean/Std foundations remain trusted.

Ordered source hashes: `OrderedSlices.lean` `3312f9904bbc9f430de9a8383ff5fb49616d25d61a00a22395059a31d1fa9c04`; tests `4783496c537227d6928d0c14d3ff2a8fc2b1821c937bf313e96de895decbb891`; added helper `ConcatenationLemmas.lean` `68d5180c0e4defa8a0e7f08efdff40a10cc51e709995e2a7e900c06b6d566309`. The exact repository base and companion file hashes are preserved in the terminal review record/checkpoint.

## Review window and recommendation

Focused review began **2026-11-17 04:49:08 UTC** and ended **2026-11-17 04:50:21 UTC** (73 seconds). Fresh replay itself took approximately 2.2 seconds; this interval includes source, instruction and closure inspection. This is review time, not author development time.

Proceed with the source-specific interval enumeration and its guards as the next small prerequisite. Keep all source assumptions and the `m ≥ n` model restriction explicit, and retain zero-width/empty cases. After that, freeze and independently check the exact Lean-elaborated rewrite goal and full import closure before any rewrite proof. This review does not independently accept a changed statement or any rewrite proof.
