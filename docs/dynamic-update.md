# Bounded DynamicSlice and DynamicUpdateSlice graphs

The update model derives a concrete same-rank window from decoded mathematical
Int starts and an extent-fit proof. Each start is clamped independently to the
legal interval. A coordinate is written exactly when every axis lies in that
computed window. There is no assumed equality of two coordinate maps.

Forty-one statements prove membership/embedding inverses, nested updates, empty
and full updates, zeroing full-axis starts, actual Select/Add graphs and legal
static Slice attributes. Seventeen retained candidate records gain explicit
mathematical evidence. This is a partial typed model; it does not close a whole
record or add a newly complete declared family to the global profile count.

## What is proved

The partial coordinate decoder recognizes every embedded update coordinate and
returns its original local coordinate. Conversely, every successful decode embeds
back to the original base coordinate. Composed membership equals sequential
decoding. These are derived from actual per-axis bounds, including rank-zero
scalars, empty axes and clipped starts.

Nested DynamicSlice and nested DynamicUpdateSlice both use the sum of the two
independently clamped starts. The existing decoded-index theory proves that this
sum fits the final window and is unchanged by reclamping. In particular,
`DUS(base, DUS(DS(base, first), update, second), first)` equals the single update
at those combined starts. The original outer slice and update share the actual
same window; aliasing or unrelated starts are not assumed equal.

A full-size window replaces the entire base. An empty update leaves the base
unchanged. Reading the exact update window returns the update, and writing the
original slice back preserves the base. A contained window reads the corresponding
slice of the update. Replacing raw starts by zero on full-size axes preserves all
read/write behavior. Pure pointwise maps commute with updates for arbitrary data
types; the tensor and scalar predicate Select transformations preserve actual
values without any arithmetic laws.

The two Add transformations preserve the actual operand order and require only
`AddZeroClass`, not associativity or commutativity. Outside the written window the
appropriate zero law is essential. They do not establish IEEE stored-value zero laws.

The static Slice attributes are constructed from the computed starts: limit is
start plus extent and stride is one. Their element counts, bounds and coordinate
maps are proved, giving actual static Slice corollaries for exact/contained update
reads. General positive-stride contained slices remain outside these corollaries.

## Refutations and controls

Three kernel certificates keep important domains separate. Signed and unsigned
decoding of byte 255 select different clamped positions (zero versus two). Adding
raw nested starts -2 and 100 produces position four, while independent clipping
produces position two. Moving actual binary32 Add inside a zero-based update
changes a retained negative-zero encoding to positive zero outside the window.
These diagnose mathematical alternatives, not source implementation behavior.
The checker also requires rejection of a default `AddZeroClass Binary32` instance.

The independent Python oracle materializes dense arrays and performs writes by
iterating update coordinates; the Lean operator decides membership from base
coordinates. They agree over 562 shape/start/data profiles, 1314 membership rows
and 19,096 operator/graph-value pairs in 20 named groups. Profiles exhaust small
valid extents and mixed signed raw starts, including scalar, empty, full and nested
windows. Both Int and actual modular 8-bit data are checked; the mathematical
raw indices remain decoded Int in both tracks. A separate actual binary32 row
checks positive-zero versus negative-zero stored words. These are development
controls, not independent held-out review. Fixture physical lengths are 112 and
4 lines, outside the primary Lean count.

## Replay and remaining workload

Run `python3 tools/check_theory.py`, `python3 tools/check_dynamic_update.py`,
`python3 tools/mathematical_ledger.py` and `python3 tools/workload_formulation_audit.py`.
The immutable input/model packet is `census/dynamic-update-v1.json`; accepted
command logs and accounting are in `reports/dynamic-update-milestone-v1.json`.
The extension adds 399 custom Lean lines: S48/H107/R207/A1/C36. Totals are 575
theory statements, 835 ledger declarations and 10,497 custom Lean lines
(S2439/H3752/R3301/A98/C907), with four integration results separate.
Existing project index theory and FloatLib operations are reused at unchanged
pins; new semantics, bounded-coordinate reasoning and graph proofs all enter LOC.
No controlled library ablation was performed.

Catalog V7 retains all 488 IDs: 244 still only proposal worksheets; record states
are 253 needing formulation/domain work, 141 partial and 94 carrying the earlier
complete value families. Those families still total 369 profile units. Whole-record
closure remains zero and N/F and the final workflow verdict remain unresolved.
The 486 statements after the original reviewed 89 await independent review.

Finite signed/unsigned decoders, conversions of combined starts and attribute
arithmetic overflow remain distinct mathematical obligations. Dynamic/effect/
physical observations, remaining operator profiles, all-case attempts and comparisons
still require work. Code correspondence remains deferred future work.

All 123 curated mathematical tests pass; exact commands and accepted logs are
retained in `reports/dynamic-update-validation-v1/`.
