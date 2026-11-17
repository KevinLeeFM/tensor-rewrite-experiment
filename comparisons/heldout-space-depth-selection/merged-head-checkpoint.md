# Merged-head checkpoint

Focused effort: approximately 3 minutes 20 seconds through the successful replay;
the replay itself compiled 36 prerequisite modules plus the candidate in 13.1s.
The current HEAD remains `2d674f4bb64566ce213f2214aabf3219595a02b4`. The original
goal freeze and recursive-decomposition freeze were read and not edited.

`MergedHeadConnection.lean` now proves `merged_head_of_tail_packing`. For shapes
of ranks `k+2` and `k+1`, if whole packed positions agree and both head and suffix
element counts agree, `full_linearize_split` followed by
`packed_component_values` proves that the replacement one-axis coordinate equals
the packed two-axis original head. The exact source-specific arithmetic reduces
to `leftHead0 * leftHead1 + leftHead1Coordinate`; the compiled theorem is the
generic reusable step, with axioms `[propext, Classical.choice, Quot.sound]`.
It introduces no assumptions about the target equality.

The actual-plan instantiation is not yet proved. It requires transporting each
actual tail shape and index through the dependent rank equalities
`k+2 = rank+1-m` and `k+1 = rank-m`, then showing the casted head element counts
agree from `tail_extents_merge` and casted suffix counts agree from
`WorkerSuffix.suffix_extents`. The actual input-shaped replacement tail also
needs the already-used shape-independence equality against the constant-input
form. `actual_tail_packed_values_equal` supplies equality of whole packed tail
positions, but this candidate does not yet connect it to the generic theorem.
This is the precise remaining integration obligation; no rewrite theorem or
actual merged-head equality is claimed.

The first compiler attempt had the final equality orientation reversed and is
retained in `merged-head-first-compile.log`. The correction compiled cleanly in
`merged-head-compile.log`. The failed log's interim `sorryAx` output belongs to
the earlier failed elaboration before replacing the unfinished proof; the final
candidate has no `sorry` or `sorryAx`. No frozen input, generic library, or other
source file changed. No independent review was requested or performed.

## Coordinator clarification and controls

The compiled equation is `replacementHead = originalCountCoordinate * originalMovedExtent + originalMovedCoordinate` (the earlier shorthand using `leftHead1` for both an extent and a coordinate is ambiguous). The saved compiler log reports 12.490 seconds; the 13.1-second figure above is an approximate worker wall-time, not the compiler log's total. During worker execution the coordinator committed the independent review, so the branch now descends from `e3ddefd` rather than remaining at the worker's initial `2d674f4`.

`MergedHeadControls.lean` was run separately against the existing local targeted build artifacts: it checks a nonempty packed-head instance, rejects a wrong merged coordinate, and shows the absence of an index for a zero extent. This control execution is distinct from the worker's fresh 36-prerequisite-plus-candidate compile; no full rewrite or plan-specific coordinate was established. The candidate remains unreviewed and the next work requires actual-plan instantiation across dependent rank/index casts, not merely its generic conditional conclusion.
