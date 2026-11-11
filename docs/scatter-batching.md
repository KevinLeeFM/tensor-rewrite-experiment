# Actual paired operand/index batching

The model now derives operand slices from actual paired batch coordinates. A
checked signed operand-axis array is paired with a checked signed index-batch-axis
array of the same length. Both are injective; paired extents agree. Operand batch
axes are actually omitted from the compact window and disjoint from the original
vector-indexed operand axes. Pair order may be arbitrary, and only a subset of
index-batch dimensions need be paired.

Index-batch axes name the vector-removed batch shape. `rawBatchAxis` derives their
actual positions in explicit or implicit raw index tensors. The raw extent and
coordinate-value lemmas prove that these are the original batch coordinates,
independent of vector-axis position. Paired axes can be nonleading. Zero-component
vectors still retain their batch dimensions even when no raw index value exists.

`position` independently specifies actual coordinates: a paired operand axis uses
its selected batch coordinate; every other axis uses the original signed index
offset plus the original window coordinate. Inserted-axis proofs force paired
window coordinates to zero, and extent equality bounds each paired batch coordinate.
All operand bounds are checked; invalid nonbatch positions retain the original
per-element drop policy. Batch/window order, duplicates and raw update reads remain.

## Derived evaluator and graph consequences

The canonical evaluator uses an actually constructed signed identity operand-axis
vector and starts derived from original index values or bounded batch coordinates.
Target equality, exact event-list equality and complete whole-state equality are
proved. No target equality, graph law or tensor correspondence is assumed. With
zero pairs, the target theorem recovers the previous unbatched sampler.

Empty batch/window and vector-axis relayout laws use no scalar algebra premise.
Word base translation keeps actual distinct current/update reducer roles, every
word width and both outer Add orientations. Nested result fusion explicitly uses
associativity and commutativity and permits different raw index-vector layouts on
the two inputs. No IEEE reassociation is inferred.

A kernel-checked example uses an actual empty raw vector and two operand batches.
Batching applies updates to separate slices, giving `[1, 2]`; forgetting the pairing
sends both updates to the first slice and gives `[12, 0]` under the same decimal
reducer. This is a declared-model attribute counterexample, not an external compiler
claim. Forgetting batching is observably different from a valid vector-axis relayout.

## Scope, controls and burden

The fixed observation remains batch-major/compact-window-major evaluation with
per-element drops and unbounded mathematical signed indices. Generic Transpose and
raw-layout Concat graph bridges, relative window permutations, whole-window-drop
semantics and permitted-order numerical observations remain open. External raw
attribute/IR admission and code correspondence are future work. The canonical
reencoding is a proved mathematical construction, not a verified emitted graph.
No full Scatter family or whole retained record closes.

Inputs are frozen in `census/scatter-batching-v1.json`. Run
`python3 tools/check_theory.py` then `python3 tools/check_scatter_batching.py`.
An independent imperative coordinate-table oracle agrees on 2035 profiles, 2071
events and 2071 outputs. They include unsorted/reordered pair arrays, partial and
nonleading batch pairing, all raw vector-axis positions through rank three,
implicit and zero-component vectors, scalar/empty shapes, interleaved updates,
unsorted spatial indices and word wraparound. Ignoring batching changes 664 observed
outputs. The 301 physical IO-fixture lines are separate from primary lexical counts.

Twenty-two statements add 360 custom Lean lines: S83/H136/R98/A1/C42. Totals are
444 theory statements, 704 ledger declarations and 9134 custom Lean lines
(S2044/H3645/R2578/A93/C774), with four integration results separate. The existing
Lean/Mathlib/FloatLib pins remain unchanged. The bridge reuses bounded raw coordinate
readers, ordered event algebra and singleton window enumeration.

The 488 retained records still partition as 347 needing formulation/domain work,
128 partial and 13 carrying 21 complete declared value profiles. All have worksheets;
374 only unreviewed proposals. Whole-record closure remains zero. The 355 statements
beyond the originally reviewed 89 await independent statement review. N/F, full
campaign attempts, residual interventions/comparisons and the final workflow verdict
remain unresolved. Exact replay evidence is in `reports/scatter-batching-milestone-v1.json`.

All 103 curated mathematical tests pass. Exact outputs of the five current-turn
validation commands are archived in `reports/scatter-batching-validation-v1/`.
Full Lake/theory axiom checks cover the previous development and this extension.
