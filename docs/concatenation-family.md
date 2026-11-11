# Pure static concatenation value family

The family snapshot `census/concatenation-values-family-v1.json` contains nine
universal guarded graph schemas. These cover the nine retained `HandleConcatenate/`
labels under the declared mathematical contracts. They do not close nine whole
benchmark records or certify an external optimizer. Retained labels are provenance;
no source guard is imported as a proof assumption.

| Profile | Complete mathematical domain |
| --- | --- |
| Unary | One arbitrary operand |
| All-empty first | Actual emptiness, with an iff characterization of complete output/first shape equality |
| One nonempty | Exactly one operand remains under actual-empty filtering |
| Many nonempty | Actual filtered list nonempty; output shape equality is derived |
| Flatten | Arbitrary ordered finite operand groups |
| Adjacent Slices | Any finite run of guarded pair merges, arbitrary surrounding operands |
| Low Pad | Leading actual scalar Broadcast, same actual fill |
| High Pad | Trailing actual scalar Broadcast, same actual fill |
| Unit-axis repeat | Repeated input of selected extent one, actual ordinary Reshape then Broadcast |

Data types and values are arbitrary. No arithmetic, data equality or default-value
instance is required. Ranks and extents are arbitrary wherever the selected axis
exists, including zero dimensions, zero Slice lengths and zero copies. The
observations are complete static shapes and every logical tensor value. Dynamic
shape execution, physical layout/memory, machine attribute overflow and discarded
execution observations require separate contracts. Independent statement review
and full retained-record partition review remain pending.

## Actual graph operators

`ConcatenationGraphs.lean` constructs existing `SlicePad.Slice` and
`SlicePad.Padding` operators. A `Crop` carries independently legal common attributes
on every nonselected axis. Selected Slices retain their raw start, exclusive limit
and positive stride. Adjacency is exactly
`second.start = first.start + firstLength * first.stride`, with a shared stride.
`merged_axis_count` derives the merged length from the original limits rather than
assuming the desired count or requiring a canonical limit. Every common legal
nonselected crop/stride is retained. `adjacent_slices_context` proves one merge;
`SliceMergeRun` contains only actual guarded replacement constructors, and
`slice_merge_run` proves every finite run preserves the packed shape/data object.
The relation has no assumed data-equality premise and does not verify an external loop.

For example, first attributes `(start=1, limit=2, stride=2)` select coordinate1.
A second Slice `(3,5,2)` selects coordinate3. Their concatenation equals the actual
merged `(1,5,2)` Slice. The first limit is deliberately not canonicalized to3.
Gapped `(0,1,1)` and `(2,3,1)` operands fail the adjacency domain; a checked
counterexample distinguishes their second value from the contiguous merged Slice.

`constantBlock` uses the existing bounded scalar Broadcast. The low/high theorems
compare its concatenation directly with the existing independent Pad semantics,
preserving the exact fill. The refutations reject changing its side or value.

`UnitAxis.ofAxis` computes the deleted shape and signed Broadcast attributes for
any legal axis. Shape, count, linear-position and decoded-axis proofs establish
that `UnitAxis.sequence` is ordinary logical Reshape deleting a singleton, followed
by the existing Broadcast map. `repeatTarget` transports complete equal shapes;
it is not a bespoke operator defined to return the desired input coordinate.
Deleting the only axis reshapes to a scalar. Empty other dimensions and zero
copies need no data inhabitant. Nonunit deletion fails the Reshape count obligation.

The earlier all-empty shape diagnosis still applies: `(2,0)` and `(3,0)` combine
to `(5,0)`, although every value domain is empty. The complete pure profile is an
exact shape/value iff, not an assertion that all-empty alone implies equal shapes.

## Replay and evidence boundaries

```sh
python3 tools/check_theory.py
python3 tools/replay_concatenation_base.py
python3 tools/check_concatenation_family.py
python3 tools/mathematical_ledger.py
python3 tools/workload_formulation_audit.py
```

The immutable v1 checker selected its whole namespace. The new adapter selects its
exact frozen48 names, uses its unchanged controls and validator, and writes a
separate replay report. Original manifests, sources, fixtures, reports and review
packets remain unchanged. Negative extension flags in that historical report
continue to describe the v1 subset, not the current family.

Independent Python arrays materialize Slice operands and concatenate full rows,
copy input cells into a fill-initialized Pad array, and reshape flattened input
values before projecting Broadcast axes. Actual Lean agrees on11544 rows across
1044 profiles:252 adjacent-Slice,648 Pad and144 repeat profiles, plus six binary32
encoding rows. Integer and actual Word8 tracks cover every axis at ranks1–3,
noncanonical limits, selected strides up to3, nonselected crops/strides, arbitrary
outer operands, empty dimensions and scalar deletion. Four well-formed false
propositions fail normally; four separate Lean refutations have no positive labels.
All143 curated mathematical tests pass. These are development controls, not a held-out or independent semantic review.

This extension adds45 statements and799 custom Lean lines:
S148/H411/R201/A1/C38. The total is696 theory statements,956 ledger declarations
and12027 custom Lean lines, with four integration results separate. Imported
Std/Mathlib finite-index/division facts and existing project operators are reused;
FloatLib supplies stored-bit controls. Pins do not change. Operational interpolated
fixtures disclose physical lines separately; unsupported interpolation is not fed
to the lexical Lean counter. No library ablation, minimum-proof-size result or
blind discovery claim is made.

Catalogv10 preserves all488 retained IDs and leaves213 with proposal-only
worksheets. The ledger has222 records needing formulation/domain work,144 with
partial evidence and122 carrying declared value families. Six declared families
have397 profile units; these units are not a denominator comparable to488 records.
Whole-record closure remains zero, mathematical N/F is unfrozen, and the full
positive/negative workflow verdict remains unresolved. All607 statements beyond
the reviewed89 require independent review. Code correspondence remains future work.
The snapshot is an accepted artifact finalized after development, not a
preregistered proof-discovery trial.
