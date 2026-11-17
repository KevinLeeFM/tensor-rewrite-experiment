# HandlePad proof attempt

**Worker verdict.** Both exact frozen logical-value goals compile, with
independent review pending. The proof applies to the two declared static
model branches. The historical unit-spacing proof is reused. The new adapter
constructs the branch's Pad attributes, including their valid shape, rather
than requiring a second well-formed parameter record. The empty-input proof
rules out every successful sample because it would contain a coordinate in
`Fin 0`. There is no proof of C++ correspondence, native execution, or complete
source-record coverage.

The freeze is `8aae9c82049dfd84b886334c9e019081cea36497`. Run from this packet:

```sh
python3 -B replay.py --lean /workspace/toolchains/lean-4.35.0-linux/bin/lean
```

This compares pinned semantic bytes, elaborates the exact frozen Propositions,
and builds their named proofs and controls in a fresh temporary directory.
It uses shipped Std artifacts. It does not rebuild or validate the historical
Mathlib tree. Fully qualified theorem identities and axiom audit are printed
in [the fresh replay receipt](REPLAY.txt). A temporary copy of the generated
historical model with an added newline was rejected by `check_freeze` in
0.012 s. The source scan of the packet's Lean files found no unchecked
evidence keywords.

The controls instantiate the exact unit and empty theorem guards. The unit
example has a changed singleton axis and a nonunit axis whose interior is
retained, signed edges, a selected non-fill value, and an interior hole.
Blindly clearing nonunit interior changes both the derived extent and the
sample result. The empty example has input shape `[0,2]` and output shape
`[2,2]` with an actual output coordinate that returns the fill. The controls
also include a fully cropped unit axis and exclude a rank-zero input from
the empty branch. Controls use kernel reduction or explicit proof terms.

## Timing and failure accounting

All displayed wall timestamps are UTC, 2026-11-17. The first observed worker
timestamp was 22:16:55. The freeze was recorded at 22:19:07, followed by the
first terminal proof/control attempt at 22:19:41. The clean six-module replay
finished at 22:20:08, an observed worker window of 193 s through replay.
Evidence packaging and independent review are separate. These are worker
window observations, not exclusive active reasoning times. The worker's
reasoning and token costs, independent reviewer time, and original discovery
time for the historical proofs are unknown here.

| Phase | Measured checks |
| --- | --- |
| Setup and extraction | First timing command failed before Lean because `/usr/bin/time` was absent. Shell timing then recorded Tensor 0.545 s and failed lattice 0.347 s. |
| Proof-only port before freeze | Std does not expose bare `add_zero` in this closure. The initial lattice error also left `+ 0` in the expected type. Qualified that identity and ported two SignedPad simp lists to equivalent Std names. Lattice 0.419 s, SignedPad 0.365 s, spec 0.300 s. No semantic definition changed. |
| Fresh spec freeze check | Four commands total 1.506 s. |
| Initial proof and controls | 22:19:41. Proof accepted in 0.288 s with allowed axioms. Controls rejected in 0.316 s (`OfNat (Fin (twoAxis …))` and `Decidable ClearsInterior` synthesis failures, cascading stuck reductions). Four prerequisite compiles 1.325 s. |
| First control repair | 22:19:53. Proof accepted in 0.321 s. Controls rejected in 0.365 s (`Expected type must not contain free variables` for a dependent bound in each successor arm). Four prerequisite compiles 1.330 s. |
| Final control repair/replay | 22:20:08. Reduce the dependent bounds explicitly to closed inequalities in the successor arms before kernel `decide`. Six commands total 1.929 s. |

Physical Lean lines, counting imports and comments: 57 new specification, 40
new theorem wrappers including audit commands, 114 new controls, and 219
materialized baseline lines across the complete extracted three-module custom
dependency set. The last count includes generated headers and the three
proof-only tactic substitutions. Std contributes additional implicit support.
There is no matched performance baseline.
