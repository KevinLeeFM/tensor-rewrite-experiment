# Raw Scatter update tensors and inserted window dimensions

The new layout model derives an actual raw-tensor input bridge. A typed axis
partition identifies batch and window dimensions wherever they occur in the update
tensor. A separate window embedding inserts singleton coordinates at operand axes
absent from that compact update window. Both structures support arbitrary ranks,
extents and insertion/interleaving patterns. Relative order within the batch axes
and within the retained window axes is preserved.

`adaptUpdates` reads the original raw update value at the bounded merged coordinate.
It projects out inserted singleton window axes. The batch/window merge inverses,
window expansion/projection inverses and complete row-major enumeration identity
are proved. `entries_eq_ordered` then derives exact equality with the existing
full-rank Scatter event list, including every payload, duplicate, dropped target
and its position. No tensor equality or event correspondence is assumed.

`scatter_eq_ordered` preserves the entire whole-state tensor under any reducer.
The bridge applies to coupled states and rounded operations without algebraic
laws. Scalar mapping requires a reducer homomorphism; base translation requires
associativity; nested result fusion requires associativity and commutativity.
The word translation theorem covers every width, both distinct current/update
parameter orders and both outer Add orientations. IEEE associativity is not assumed.
An empty actual batch or compact window preserves the original state.

## Observation order and remaining scope

The declared operator uses batch-major/compact-window-major order, independent of
the raw tensor's dimension order. A kernel-checked certificate uses an actual
window/batch tensor and overlapping windows: the declared order returns 112 while
raw storage order returns 31 under a decimal reducer. Therefore changing the order
requires additional algebraic laws or a different observation contract. The
counterexample makes no external execution or scheduler claim. The diagnostic
alternate evaluator lives in the counted C file, separate from the positive model.

Indices remain batch-indexed vectors with injective signed operand-axis maps.
Elementwise out-of-bounds updates are dropped without clamping. Operand/index
batching, implicit index-vector representations, arbitrary relative window-axis
permutations, transpose and whole-window-drop bridges remain unproved. The earlier
[leading-axis tensor Concat bridge](scatter-concat.md) and this raw-input adapter
are separate proved profiles; general raw-layout Concat composition remains open.
No full Scatter family or whole benchmark record closes. Candidate corpus labels
are uncertified provenance. Code correspondence remains deferred future work.

## Evidence and burden

The frozen inputs are in `census/scatter-layout-v1.json`. Run
`python3 tools/check_theory.py` and `python3 tools/check_scatter_layout.py`.
The checker compares actual Lean outputs with an independent imperative coordinate
oracle that constructs raw tensor coordinates from separate dimension masks.
All 197 profiles, 201 events and 830 outputs agree. They include scalar/empty shapes,
zero compact/batch extents, raw rank-four interleaving, inserted front/middle/back
axes, reversed/omitted index axes, whole coupled states and word wraparound. Four
observed outputs differ under raw storage order. The IO fixture has 149 physical
lines, disclosed separately from primary lexical Lean counts.

Sixteen statements add 278 custom Lean lines: S67/H94/R84/A1/C32. Totals are 402 theory
statements, 662 ledger declarations and 8506 custom Lean lines
(S1880/H3413/R2418/A91/C704), with four integration results separate. The pins and
imported-library accounting are unchanged. The model reuses existing coordinate
partitions and ordered event algebra, rather than postulating a new graph law.

The mathematical campaign remains unfinished: zero whole records closed; N/F not
frozen; 21 complete declared value profiles retained. The 488 retained records still
partition as 347 needing formulation/domain work, 128 partial and 13 carrying complete
value families. All 488 have worksheets, 374 only unreviewed proposals. The 313
statements beyond the original reviewed 89 await independent statement review.
Kernel acceptance and controls do not replace that review or establish a workflow
verdict. Exact current replay results are in `reports/scatter-layout-milestone-v1.json`.

All 93 curated mathematical tests pass. The five current-turn validation commands
and exact outputs are archived in `reports/scatter-layout-validation-v1/`. The full
Lake build and axiom audit cover the existing theory as well as this extension.

The subsequent [raw index-reader bridge](scatter-indices.md) adds actual explicit
and implicit vector representations and lossless coordinate relayout. The frozen
v1 layout profile stays unchanged; operand/index batching and generic graph
Transpose/Concat bridges remain open.
