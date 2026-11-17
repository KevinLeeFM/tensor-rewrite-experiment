# Independent index and reshape review

Fresh Luna reviewer; read-only, no children or builds, approximately six minutes focused effort. Scope: `Pilot/IndexMaps.lean`, `LinearIndexLemmas.lean`, `ReshapeLemmas.lean`, actual definitions and selected consumers.

`BroadcastAxes` verifies signed axis range, and `broadcastIndex` requires extent agreement; it does not encode any source-required uniqueness or ordering. `sliceIndex` uses `SliceShape.IsWellFormed` to establish bounds. These are bounded model maps/view constructors, not target-rewrite equalities. Selected consumers include `Pilot/IndexMapLemmas.lean:13–48`, `Theory/UnitAxisLemmas.lean:74,128` and paper case modules.

`LinearIndexLemmas.lean:12–42` gives both inverse laws for well-typed bounded coordinates, including rank zero. `Theory/FiniteSum.lean:37–49` constructs a coordinate equivalence and `Pilot/ReshapeRules.lean:13–29` uses the inverses. `ReshapeLemmas.lean:15–47` derives empty extensionality and reshape composition under count equalities; the constant case separately requires `operand.isAll value = true`. Selected uses include `ReshapeRules.lean:14–37`, `ReductionRules.lean:37,47`, `ContractionRules.lean:30`, and `Theory/ReductionWindowAlgebra.lean:53`.

No circularity, hidden desired-output equality or justified cleanup was found in this sample. This does not audit all theorem dependencies, source correspondence or the 109-module closure.
