# Worker index proof checkpoint

- Starting checkout: `b34e4cd8022ae7d1fdae50e2bb3a4df6f744eddc`.
- Work window: began after the coordinator's 2026-11-17 06:08:20 UTC handoff; checkpoint written 2026-11-17 06:10 UTC (see filesystem timestamp for exact minute/second).
- Target remains unchanged: `originalIndex plan out = replacementIndex plan input out` for arbitrary frozen `Conditions`.
- Frozen goal/assumption semantics were not changed. Work is in `WorkerIndexJoin.lean` only.

## Result

Added generic `join_components_equal`: equal values of two valid `FiniteProduct.join` coordinates imply equality of both row and column `Fin` values, with the same row and column extents. It uses existing `row_join` and `column_join`; it does not contain target-specific assumptions or desired rewrite facts. A focused Lean 4.35.0 compile succeeded and reported axioms `[propext, Classical.choice, Quot.sound]`.

Command for helper replay (after building the two imports into a fresh temporary `LEAN_PATH`):

```
/workspace/toolchains/lean-4.35.0-linux/bin/lean TensorRewrite/Pilot/FiniteProduct.lean -o "$tmp/TensorRewrite/Pilot/FiniteProduct.olean"
/workspace/toolchains/lean-4.35.0-linux/bin/lean TensorRewrite/Pilot/FiniteProductLemmas.lean -o "$tmp/TensorRewrite/Pilot/FiniteProductLemmas.olean"
LEAN_PATH="$tmp" /workspace/toolchains/lean-4.35.0-linux/bin/lean comparisons/heldout-space-depth-selection/WorkerIndexJoin.lean
```

The initial compile command failed because the temporary output directory lacked `TensorRewrite/Pilot`; the retry created that directory and passed. The exact failure was `failed to write .../TensorRewrite/Pilot/FiniteProduct.olean: failed to create file`.

## Remaining target obligation

This generic injectivity lemma does not establish that the actual original and replacement outer frames have matching prefix/tail element counts, nor that their packed split values are equal after the source permutation and chunk slice coordinate mapping. Existing `outer_packed_parts_equal` already states equality of combined packed parts, and the coordinator is developing the distinct suffix-shape obligation. Once source-specific extents align, `join_components_equal` can recover equality of packed prefix and tail components. The frozen per-axis residual remains unsolved; no rewrite proof or acceptance is claimed.

## Time

Coordinator handoff start: 06:08:20 UTC. Checkpoint: approximately 06:10 UTC. Active inspection, authoring, and compilation consumed about 95 seconds; compile activity was under 2 seconds. The first failed compile and successful retry are both retained here. This is only this worker's interval, not total experiment time.
