# Bounded index transport attempt

The frozen goal and 28 manifest inputs remain unchanged. This checkpoint is an unreviewed partial result, not a proof of `Goal`. The outer-rank premise remains a model restriction rather than a source invariant; C++–Lean correspondence and speedup are not established.

`IndexTransportAttempt.lean` defines the actual composed input coordinate of the original graph and the input coordinate selected by the replacement. Theorems `original_read` and `replacement_read` prove that each graph reads its stated coordinate. The latter applies the independently reviewed `select_coordinate` bridge, including the shape and quotient/remainder casts. `read_equal_of_index_equal` is explicitly conditional on equality of those coordinates; that equality is not assumed by the goal and has not been proved. The module also proves that arbitrary-rank reshape preserves packed coordinate and transpose reads the inverse-permuted coordinate.

The inverse fact is reused from existing `TensorRewrite.Pilot.LinearIndexLemmas`, which imports `FiniteProductLemmas`; neither module belongs to the frozen closure. Both were previously inspected and the additional candidate imports are declared in the new file. No existing generic library or frozen module was modified. All printed dependencies are limited to `propext`, `Classical.choice`, and `Quot.sound`.

## Concrete obstacle and failures

The attempted `funext i; apply Fin.ext; simp only [originalIndex, replacementIndex, Tensor.transposeIndex, Fin.val_cast]` leaves the equality of the source-axis values computed by (a) arbitrary-rank reshape–transpose–reshape and (b) chunk selection, frame transport and inverse reshape. The complete Lean residual and unused-simp warning are in `index-transport-failure.txt`. The remaining work must derive this equality from the actual permutation and shape conditions; neither the two generic component lemmas nor quotient/remainder selection alone supplies it. No goal equality or index equality is postulated.

An initial concrete test importing `GoalCandidateTests` failed because its test fixtures are private to that module. The successful replay instead extends an isolated copy of that frozen test source without editing it. The two input coordinates were each checked on all three axes of the existing nonempty plan, yielding (0, 0, 3). A temporary Lean search-path attempt also failed because an incomplete namespace directory shadowed the built module tree; the fresh replay below uses a single complete clean build directory.

## Timing and validation

Focused work started 05:31:18 UTC and reached this checkpoint around 05:33:40 UTC (approximately 142 seconds, including replay; setup and past work are separate). `replay_index_transport.py` rebuilds 22 modules offline in an empty temporary directory, then checks the frozen goal examples plus six concrete coordinate controls. It passed in 7.216 seconds on Lean 4.35.0; compiler outputs and exact module timings are in `index-transport-replay.json`. The frozen manifest was checked during replay. A full general rewrite proof, final independent review, and broader performance comparison remain outstanding.
