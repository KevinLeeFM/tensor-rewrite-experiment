# Ordered Scatter state, geometry and partial fusion proofs

This milestone installs a mathematical full-window Scatter profile with actual
bounded address generation. It adds36 statements in480 custom Lean lines
(S65/H246/R118/A1/C50), reusing existing indexing, scalar-role and FloatLib code.
No library or toolchain pin changes. Inputs are frozen in
`census/ordered-scatter-v1.json`; all new statements await independent review.

## Actual operator and observation contract

An `Entry` contains an optional bounded operand coordinate and one whole scalar
state. `step` updates exactly that address, or ignores an absent target. `run`
processes entries by the original left fold. `run_at` derives its coordinatewise
meaning as the ordered fold of values actually targeting that coordinate; it does
not assume that ordering, uniqueness or associativity is irrelevant.

`Plan` has arbitrary operand rank, batch rank and index-vector size. Its actual
attributes include operand/batch/window shapes and an injective signed index-axis
array. The array may be unsorted and may omit operand axes. `offset_mapped` and
`offset_unmapped` prove actual component lookup and omitted-axis start zero.
`target?` adds the decoded integer start to the full-rank window coordinate and
checks bounds on every axis. It does **not** clamp. An out-of-bounds element is
dropped; its original event remains in the trace with no target.

Events are built in batch-major/window-major row-major order. The model includes
scalar operands, scalar batches, empty batches/windows, overlapping windows and
repeated indices. Its element-drop policy is explicit: a whole-window-drop
convention is not proved equivalent. General inserted axes, arbitrary update-window
layouts, operand/index batching and implicit index-vector representations are not
silently supplied by the full-rank window profile. Mathematical index arithmetic
is unbounded Int; external word decoding/attribute overflow admission remains open.

The reducer state is an arbitrary type, including coupled tuples. State mapping
requires an actual reducer homomorphism and maps the original base/update payloads.
The empty-components theorem covers outer tuples of tensors with the same logical
operand shape, even for heterogeneous component types and a coupled reducer. It
does not drop state merely because one component is being observed. Physical,
ambient effect, flag and external IR observations are outside this pure model.

## Proved graphs and algebra

Zero batch or window element count gives no event and returns the original base,
without reducer laws. Empty index vectors with a **scalar batch and full window**
produce exactly one original event at every valid operand coordinate. The actual
Scatter therefore equals pointwise binary Map, including scalar/empty shapes and
arbitrary whole-state reducers. No sample-map equality is postulated.

Associativity derives translation of a separate left base factor through the
ordered trace. Associativity plus commutativity derives combination of two
independent traces into their concatenation or the actual nested `run` target.
No zero initializer is introduced. Arbitrary-width word Add instantiates these
laws even when intermediate values wrap.

For the actual word reducer `ScatterRoles.combine`, distinct current/update
parameter roles derive equality with ordinary word addition. The graph theorem
covers both parameter orders and both outer Add orientations. An Add-shaped root
with repeated parameter roles is not assumed to be ordinary addition.

The concatenated-event algebra is proved. The bridge from Concatenate of actual
index/update tensors to the target Scatter event enumeration is still **unproved**,
as is the general transpose/dimension-number bridge. Those remain mathematical
work, separate from deferred code correspondence. `run_combine` is partial core
evidence for a concat case, not a complete theorem about that retained target.
No full Scatter family or whole benchmark record closes here.

Four checked certificates expose weakened contracts:

- Two repeated-current four-bit updates give original11 versus translated4.
- Reversing duplicate-address decimal updates gives12 versus21.
- Actual scalar binary32 Scatter/Add translation changes finite stored bits from0
  to `0x3f800000`, so IEEE associativity is not inherited from exact/word proofs.
- Dropping a negative target preserves base2; clamping it to coordinate0 instead
  applies update9 and gives11.

These are declared-model contract counterexamples, not external compiler bug claims.

## Validation, accounting and corrected metadata

An independent dense-table oracle builds signed start/window addresses and applies
updates imperatively. It does not use the Lean filtered-coordinate fold theorem.
All2709 profiles/3354 events/2968 outputs,11872 four-bit reducer-role controls and
four finite binary32 controls agree. Cases include permuted/omitted index axes,
negative/overshooting starts, duplicate targets, coupled states, empty/scalar
shapes, modular wraparound and full-window Map. Finite binary32 controls use the
existing exact-rational oracle. The interpolated IO fixture's physical length is
reported separately from primary lexical Lean counting in the milestone JSON.

The ledger previously copied both Scatter-role and Gather-literal candidate labels
from one retained packet onto each diagnostic. Current metadata now separates the
`ScatterRoles` and `GatherLiterals` mathematical namespaces, with narrowed profile
descriptions. No proof body, frozen pilot packet or historical evidence baseline
was rewritten, and candidate label correspondence remains uncertified. A passing
proof with an unrelated candidate label would still be misleading evidence.

Run `python3 tools/check_theory.py`, `python3 tools/check_ordered_scatter.py`,
`python3 tools/mathematical_ledger.py` and `python3 tools/workload_formulation_audit.py`.
Exact replay commands/logs are archived in `reports/ordered-scatter-validation-v1/`.
All86 focused tests pass. The suite checks data/axis/drop/order/role/claim mutations, dependency drift,
legacy metadata separation and whole-workload limits. Integrity tests for the earlier
proposal packet continue to replay its frozen catalog v2.

Catalog v3 adds a six-record Scatter refinement to the488-ID catalog;374 records
have only the unreviewed proposal worksheets. This refinement is not independent
semantic review. Theory totals become377 statements,637 ledger declarations and
8027 custom Lean lines (S1776/H3220/R2270/A89/C672), with four integration results
separate. Complete declared value profiles remain21. Record statuses are347
needing statement/domain work,128 partial and13 carrying value families. Whole-record
closure remains0. The288 statements after the original reviewed89 await review.
Mathematical N/F, all-case attempts, remaining models/bridges, residual diagnosis,
comparisons and the final workflow verdict remain open; code correspondence is future work.


The first integration replay stopped at an audit-reader KeyError because that
reader assumed every worksheet had one retained input batch. The cross-batch
schema now validates both input hashes and the union of retained IDs. The failed
run is preserved under `reports/ordered-scatter-validation-v1-first-attempt/`.
Unchanged successful model checks are reused with original log hashes; the audit
and full focused suite pass after the reader fix. This infrastructure failure is
not classified as mathematical proof difficulty or a refuted Scatter theorem.

The subsequent [leading-axis input bridge](scatter-concat.md) derives actual tensor
Concat to event append for arbitrary shared trailing batch dimensions. The frozen
v1 report remains the earlier trace-only milestone; general dimension/layout
bridges and whole-record closure remain open.

The subsequent [raw update-layout bridge](scatter-layout.md) derives interleaved
batch/window tensor reads and singleton window insertions. Its precise remaining
dimension/order boundaries supersede the earlier unsupported-layout description
for that new profile; the original frozen milestone is retained.
