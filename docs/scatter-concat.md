# Tensor-input concatenation and ordered Scatter

The leading-batch-axis input bridge is now proved. `ScatterConcat.concatenate`
constructs the actual bounded index and update tensors; its inputs are tensors,
not event traces. `entries_concatenate` derives that their Scatter event list is
exactly the original left trace followed by the right trace.

The profile permits arbitrary operand rank, full-rank window shape, index-vector
size, leading batch extents and common trailing batch rank/extents. Both sides use
one operand/window geometry and one injective signed index-axis array. The original
start-plus-window bounds checks, per-element drops, duplicate targets and payload
pairing remain unchanged. Empty batches, zero trailing extents and scalar operands
are included. This is a logical value model with explicit ordering.

`scatter_concatenate` consequently equates the actual concatenated-input Scatter
to sequential left/right Scatter for any whole-state reducer. There is no
associativity, commutativity, uniqueness or component-independence premise.
`scatter_combine` combines two independently initialized Scatter results into one
concatenated-input Scatter under associativity and commutativity. The combined
base uses the same binary operation. `word_combine_distinct` instantiates the law
at every word width, including wraparound and both distinct current/update reducer
parameter orders. Repeated parameter roles and IEEE reassociation are not assumed.

This extends the [previous ordered Scatter milestone](ordered-scatter.md), whose
frozen trace-only report remains historical evidence. It closes the input bridge
for this leading-axis profile, not arbitrary-axis concatenation, inserted/update-
window/batching dimensions, implicit vector layouts, transpose transformations,
whole-window-drop semantics or external IR admission. Those are still mathematical
obligations. Code correspondence remains user-deferred future work. The retained
`HandleAdd/scatter-concat` label is candidate provenance, not a certified match.

## Evidence and size

The frozen inputs and exact claim flags are in `census/scatter-concat-v1.json`.
Run `python3 tools/check_theory.py`, then `python3 tools/check_scatter_concat.py`.
The first command builds all Lake targets and checks transitive axioms; the second
compares actual Lean evaluations with an independent imperative coordinate-table
oracle. The oracle constructs dense concatenated inputs by coordinate, without
using the proved event-append identity. All540 profiles,1890 events and810 outputs
agree, including a nonassociative decimal reducer that exposes order, exact integer
result fusion and four-bit modular result fusion. The107 physical IO-fixture lines
are disclosed separately from primary lexical counts.

Nine statements add201 custom Lean lines: S37/H99/R64/A1/C0. Totals are386 theory
statements,646 ledger declarations and8228 custom Lean lines
(S1813/H3319/R2334/A90/C672); four library integration results remain separate.
The pins and imported-library accounting are unchanged.

The full mathematical workload is unfinished: zero whole records closed; N/F not
frozen;21 complete declared value profiles retained. The488 provisional records
still partition as347 needing statement/domain work,128 partial and13 carrying
complete declared value families. All488 have worksheets,374 only proposal
worksheets. The297 later statements beyond the original reviewed89 await
independent statement review. Tests and kernel acceptance do not supply that review
or a final feasibility verdict. Replay logs and exact metrics are recorded in
`reports/scatter-concat-milestone-v1.json`.

All89 curated mathematical tests pass. The five current-turn validation commands
are archived in `reports/scatter-concat-validation-v1/commands.json`. The full Lake
build and axiom inventory include the existing theory; no native pass replay or
code-correspondence investigation was performed.
