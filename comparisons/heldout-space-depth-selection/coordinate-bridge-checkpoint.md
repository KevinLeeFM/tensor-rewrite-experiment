# Coordinate bridge checkpoint — review requested

The frozen rewrite goal and all 28 recorded input hashes remain unchanged; this is a separate candidate, not an accepted proof of that goal. The source-to-model correspondence remains an assumption and `outerRankAtLeast` remains a model restriction, not a source invariant.

## Existing inverse and import decision

`TensorRewrite/Pilot/LinearIndexLemmas.lean` proves both directions of the linearize/delinearize inverse at arbitrary rank. Its direct imports are frozen `LinearIndex` and the additional `FiniteProductLemmas`; the latter imports frozen `FiniteProduct`, whose remaining dependency is Lean Std. Inspection of both new modules found generic finite-product and inverse lemmas, with no target rewrite or desired equality. They are outside the 28-file frozen closure, however: importing them into the frozen goal would alter the baseline. Their SHA-256 values are `f5850dd78c05d62837a026f7fed3c73c0206e916fa2b57148b1e4f1c597118ff` and `846b504cd4bd6bb2039dbc25d8cb6c325856393268b799b8438457a70ea29711`, respectively. This candidate leaves that closure untouched and uses the inverse-free frozen product definitions.

## Candidate and limitation

`CoordinateBridge.lean` derives quotient and remainder after an arbitrary equal-size `Fin.cast`, reconstructs the original cast coordinate, and establishes absence of positions for either zero product factor. `CoordinateChunkAdapter.lean` connects those actual bounded quotient/remainder values to `chunkPosition` and the previously established `chunk_select`; in particular, `select_coordinate` reads any valid concatenation position using its associated enumerated source interval. These statements are generic in the frame, axis, sizes, element type and input tensor; they do not assume a rewrite equality. The independent review must assess this claim and the exact statements.

`CoordinateBridgeTests.lean` checks the first and last positions, a block boundary, one block, both zero factors, and a concrete swapped-quotient/remainder wrong-result control. A zero selected extent has no admitted position; zero extents elsewhere in the full tensor similarly make full indices empty but are not newly tested by this arithmetic-only module. The existing frozen goal controls cover examples with unrelated and slice-width zero extents. All candidate axioms printed by Lean are confined to `propext`, `Classical.choice`, and `Quot.sound`.

The adapter does **not** connect the original reshape–transpose index to the output coordinate, prove the whole tensor rewrite, or establish C++ correspondence. That index transport and dependent frame reasoning remain. The candidate is unreviewed and does not change the frozen proof baseline.

## Effort and replay

Focused construction and inspection ran approximately 05:25:01–05:26:23 UTC (82 seconds including the 3.18-second fresh replay); prior setup and earlier proof/review times are separate. A first compile failed only on the two zero-factor `simp` proofs; replacing them with elimination of `Fin 0` compiled. The fresh offline replay rebuilt the 10 needed modules into an empty temporary directory with Lean 4.35.0 and checked all 28 frozen hashes; its compiler outputs, timings, and candidate hashes are in `coordinate-bridge-replay.json`. No downloads, full build, or rewrite-proof attempt was run. Independent review remains outstanding.
