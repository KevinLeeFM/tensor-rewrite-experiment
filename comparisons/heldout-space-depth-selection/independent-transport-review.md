# Independent single-slice transport review

**Disposition: accepted as a viable generic single-slice prerequisite, with a bounded-controls caveat.** The construction transports the actual `Frame.slice` tensor into a frame selected on a possibly different axis by a derived equality of shapes. This does not establish an ordered-block concatenation theorem, the proposed space-depth rewrite, or readiness to prove that rewrite.

## Checkpoint and inspected material

- Repository: `/workspace/tensor-heldout-chunk-20261117`, exact `HEAD` `fea75b4e192f100c4abd2dfb69a7c99bdcceffd4`; worktree was clean before review and remained unchanged except for this report.
- Read `AGENTS.md` (SHA256 `2b6f58a812fe96ca5cf2395413e4709e60cebd60acd867b06f76118e8db90cee`), the transport report, previous independent pre-proof review, `ALLOWED-IMPORTS.json`, and the complete `SliceTransport.lean`, `SliceTransportTests.lean`, and `replay_transport.py`.
- Inspected the full actual `TensorRewrite/Theory/Concatenation.lean` (SHA256 `63442258c805c25bcc6147d877f6220036504e7a6bdcd95549dcb069a11bdd56`) and `TensorRewrite/Pilot/Tensor.lean` (SHA256 `c1b41d38bee3d55c4a63df7333c7f0d23ea5917e4260062e2efad97edbeab122`). The former imports only `Pilot.Tensor`; the latter imports only `Std`. `Shape` and `Tensor` are arbitrary finite-rank functions, and `Frame.slice` constructs the source slice with bounded-coordinate arithmetic. There is no target rewrite theorem in this two-module closure. The proposed larger nine-module allowlist is not imported by this transport and was not treated as a proof closure for a rewrite.
- Read pinned source `sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc:10589–10740` (SHA256 `1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f`) and the selected-case checkpoint. Source inspection supports the interpretation of splitting one axis and slicing before concatenating on another; it does not prove C++/Lean correspondence or visitor reachability.

## Mathematical and control review

The definitions are rank-polymorphic and use arbitrary `α : Type`. Supplying the destination axis requires `Fin rank`, so rank zero is naturally outside this selected-axis operation. `destination_shape` proves the destination frame at the source's original selected-axis extent equals the slice shape. `destinationIndex` casts coordinates along that derived equality; `destinationIndex_value` proves their natural values are unchanged. `sliceBlock` packages the existing actual `Frame.slice`, and `sliceBlock_read` is its definitional read equation. This construction does not require distinct source and destination axes; only `destination_extent_of_distinct` uses that hypothesis.

Zero lengths and zero extents are represented honestly: an empty index domain has no fabricated value. The concrete controls check a nonzero start and nonzero coordinates (`22`, distinguishing `12`), an end-at-boundary slice (`32`), an empty slice at the end, a zero-length index domain, another zero axis, same-axis construction, and the failed inequality for an out-of-bounds fit. The tests are finite examples, not a general proof of emptiness behavior beyond the definitions. The out-of-bounds case only shows the fit proposition is false; it does not attempt to apply the constructor without a fit proof. There is no wrong-concat-axis control yet, which is appropriate for this one-slice module but must be added at the ordered-block/rewrite stage.

No new axioms, `sorry`, `admit`, or `native_decide` appear. Fresh replay printed these axiom dependencies:

```text
destination_shape: [propext, Quot.sound]
destinationIndex_value: [propext, Quot.sound]
destination_extent_of_distinct: [propext]
sliceBlock_read: [propext, Quot.sound]
```

These are ordinary Lean dependencies for the definitions/equalities in this closure; no target-specific equality is assumed. The read theorem is definitional rather than an independent semantic characterization.

## Fresh replay and timing

Rebuilt only `TensorRewrite/Pilot/Tensor.lean`, `TensorRewrite/Theory/Concatenation.lean`, `SliceTransport.lean`, and `SliceTransportTests.lean` with `/workspace/toolchains/lean-4.35.0-linux/bin/lean` 4.35.0. Outputs went to a fresh `/tmp` import directory; no tracked replay receipt was touched. All four commands succeeded, and the transport module emitted the axiom lines above. The isolated command sequence took about 1 second of measured shell time (5.2 seconds including tool startup/dispatch). An initial attempt to use `/usr/bin/time` failed because that executable is absent; it made no repository changes.

Focused review interval: **2026-11-17 04:41:09–04:41:50 UTC**, about 41 seconds including inspection and replay. This is reviewer time, not author development time.

## Smallest next ordered-block prerequisite

For a fixed distinct concat axis and a finite ordered list of source slices, construct each block in that same concat frame and derive its extent and fixed extents from the slice shape. Then prove the list's total extent and exact output shape, followed by a pointwise `readAt` selection lemma: a concat-axis coordinate in block `i`'s segment selects precisely slice `i` and maps to source split coordinate `i * chunk_size + local`. Include zero-width blocks (`chunk_size = 0`), zero chunks if the source/model guard permits them, other zero axes, and segment boundaries. The source guard appears to make chunk count positive in the selected natural-number model, but this remains a model/source interpretation to state explicitly. Keep this prerequisite separate from the final reshape/transpose theorem and do not smuggle its desired equality in as a premise.
