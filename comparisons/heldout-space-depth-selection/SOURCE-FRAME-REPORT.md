# Source-frame construction: pre-goal checkpoint

Status: **the requested chunk-specific wrong-axis control and source-frame shape/axis derivations compile; the exact full rewrite goal is not yet elaborated or frozen**. No final rewrite proof, independent review of these new declarations, C++ correspondence or source-branch completion is claimed.

## New checked material

`ChunkIntervalsTests.lean` now tests three actual source-style chunks, comparing correct concat axis 1 at index [0,3] in shape [2,9] against wrong axis 0 at [1,0] in shape [6,3]. Both are row-major flat position 3; the well-typed values are 20 and 10. This is a finite negative control, not a theorem about all wrong axes. Its fresh seven-module replay passed; the old receipt is preserved as `chunk-replay-before-wrong-axis.json` and the newer one as `chunk-replay.json`.

`SourceFrame.lean` constructs an input `Frame` from an arbitrary source shape and split axis. From the source-shaped premise `shape[split] = count * width`, `source_shape` proves equality between the framed shape and original shape, and `framedInput` casts bounded coordinates through that derived equality without changing coordinate values. The equality is a source-loop product guard, not a target-rewrite equality.

`AxisConditions` records a bounded output-to-input `AxisPermutation`, split, moved axis, selected-axis fact, inequality and exact offset check. `moved_before_split` uses the permutation inverse and previously reviewed arithmetic bridge; `concatAxis` derives a legal input-rank axis, and `concat_distinct` proves it differs from split. `concatFrame` builds the actual existing destination frame. `chunk_output_shape` derives every axis of the actual `chunkBlocks` concatenation shape: the concat extent is `count * original[concatAxis]`, split extent is width, all other extents unchanged. It uses the actual generic slice/block construction, not an assumed tensor equality. Finite tests include shape [3,4,6], derived [3,8,3], zero on a separate axis, one chunk, width zero with positive other extents, a wrong product and a bad moved-axis condition.

The model deliberately does not say every `AxisConditions` instance is reached by the native source visitor. Its structure represents a relevant subset of source permutation conditions; the future full goal must also state the first-split mismatch/prefix/suffix, count cap, representable signed arithmetic, original reshape/transpose legality and output checks. The previously disclosed **outer rank ≥ input rank is a model restriction**, not a proved native invariant. Zero dimensions remain permitted; generic count 0 and width 0 behavior is not silently equated with source branch reachability.

## Concrete remaining blocker to a well-typed exact goal

`Reshape.reshapeTensor` requires a proof that source and destination `LinearIndex.elementCount` are equal. To use the actual inner transpose and actual concatenated output rather than a substitute operator or a theorem-shaped assumption, the missing named generic prerequisites are:

1. For arbitrary legal rank/axis permutation, derive that transposing shape axes preserves `LinearIndex.elementCount`.
2. From `shape[split]=count*width` and the derived distinct concat/split axes, prove that `chunk_output_shape` has the same element count as `shape`, including width 0, count 0 in the generic helper, and zero extents on other axes. Then use original valid output reshape's element-count condition to construct the actual RHS reshape witness.

A text search found `LinearIndexLemmas` inverse-position lemmas and several specialized element-count lemmas, but no audited general axis-permutation/two-axis redistribution theorem. Existing larger project proof modules cannot silently enter the held-out generic closure; any reusable proof must be inspected for overlap and import contamination. Assuming these unproved equalities as extra plan premises would silently strengthen the mathematical target and defeat the requested derivation. No such assumptions were added, and the prose draft has not been relabeled an exact Lean goal. This is the exact next bounded shape-product prerequisite; stop/review if it becomes general library reconstruction.

## Checks and timing

A fresh temporary-import replay compiled 12 small modules with Lean 4.35.0, pinned compiler commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc; it passed in 4.167 seconds. `source-frame-replay.json` contains per-file source hashes, outputs and axiom reports. All seven `SourceFrame` theorem reports use only propext/Quot.sound or no axioms. `source-frame-proposed-hashes.json` records this proposed import/test closure and pinned source; it is **not** a frozen final-goal manifest and requires independent audit. No sorry/admit/native_decide/new project axioms appear in the accepted helper.

Work began 2026-11-17 04:58:15 UTC; the fresh replay completed 05:01 UTC. Earlier `SourceFrameTests` failed once because count/width could not be inferred; explicit type parameters fixed the test without weakening its conditions. Full attempts and compiler times are in `source-frame-attempts.json`; setup/replay commands are separately recorded. An earlier rejected `sorryAx` diagnostic belongs to a prior failed attempt and is never accepted. There is no independent review time or speedup claim for this phase.
