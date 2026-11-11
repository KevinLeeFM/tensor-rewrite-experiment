# Explicit and implicit raw index tensors

`IndexVector.Layout` represents exactly one explicit vector axis at any raw tensor
position, or an implicit vector with exactly one component. The type fixes the
component count and the remaining batch shape. It permits arbitrary ranks and
extents, empty batches and explicit zero-length vector axes. An implicit vector is
not an empty vector: its raw tensor retains every original batch coordinate.

The reader derives actual bounded raw coordinates by inserting the component at
its vector axis. Batch/component projections are proved inverse to insertion in
both directions. `read_pack` and `pack_read` establish lossless tensor round trips;
`elementCount_raw` derives batch count times component count. Explicit axis bounds
and the implicit-one-component property are proved.

`relayout` constructs an actual raw tensor by bounded coordinate reads. Its reader
is proved equal to the original reader; identity and composition laws are checked.
This includes moving an explicit axis and introducing/removing an explicit singleton
axis. Relative batch order is retained. Scalar conversion commutes with reading,
but this does not identify signed and unsigned decoders or justify narrowing.

## Both raw tensor inputs to Scatter

`ScatterIndices.entries` reads raw indices at the derived vector coordinate and
raw updates at the existing merged batch/window coordinate. Its exact event list
and whole-state tensor derive the previous compact/interleaved evaluator and the
original full-rank evaluator. Addresses, dropped targets, duplicates, payloads and
batch/window order are retained. No reducer algebra law is used for these input
bridges or for vector-axis relayout. Word base translation uses the actual distinct
current/update parameter roles and applies at every width and both Add orientations.

A kernel-checked counterexample has an actual raw index shape `[0, 2]`: zero raw
index elements, two admitted batches and two ordered updates. The decimal Scatter
result is 12, while the tested first-update pointwise Map gives 1. Raw index
emptiness alone therefore does not establish an empty event trace or single Map.
This is a mathematical counterexample to that weakened contract, not a source guard
or compiler bug claim. The earlier scalar-batch/full-window Map theorem remains valid.

Operand/index batching, relative batch/window permutations, generic Transpose graph
bridges, whole-window-drop semantics and general raw-layout Concat composition remain
open. The proved coordinate relayout is not silently identified with an external
Transpose or Reshape construction. The index-axis map remains injective and signed;
external attribute/IR admission and code correspondence are future work. No full
Scatter family or whole retained record closes here.

## Reproduction and burden

Inputs are frozen in `census/scatter-indices-v1.json`. Run
`python3 tools/check_theory.py` then `python3 tools/check_scatter_indices.py`.
An independent dense-coordinate oracle agrees on 162 reader profiles, 230 raw
values, 230 batch/component reads, 230 relayout target values, 305 Scatter profiles,
381 events and 1115 outputs. Cases include all vector-axis positions through raw
rank three, scalar/empty batch shapes, implicit/singleton conversion, explicit zero
vectors with nonempty batches, interleaved/inserted update layouts, signed/unsigned
observations and word wraparound. The 211 physical IO-fixture lines are separate
from primary lexical Lean counts. Existing coupled-state controls remain in the
regression suite; this extension's new controls use decimal and word reducers.

Twenty statements add 268 custom Lean lines: S81/H96/R62/A1/C28. Totals are 422 theory
statements, 682 ledger declarations and 8774 custom Lean lines
(S1961/H3509/R2480/A92/C732), with four integration results separate. The existing
Lean/Mathlib/FloatLib pins are unchanged. Generic raw readers use Lean/Std and reuse
the project's bounded tensor coordinates; Scatter reuse retains its existing
Mathematical library closure. New definitions/adapters enter the primary count.

All 488 retained records still have worksheets, 374 only unreviewed proposals;
347 need formulation/domain work, 128 have partial evidence and 13 carry 21 complete
declared value profiles. Whole-record closure remains zero; N/F and the full
workflow verdict remain unresolved. The 333 statements after the originally
reviewed 89 await independent statement review. Exact validation evidence is in
`reports/scatter-indices-milestone-v1.json`.

All 98 curated mathematical tests pass. The five current-turn validation commands
and exact outputs are archived in `reports/scatter-indices-validation-v1/`. Full
Lake build and axiom checks include existing theory and the new extension.
