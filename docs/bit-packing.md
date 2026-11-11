# Exact stored-word packing and partial Bitcast graphs

The mathematical model in `census/bit-packing-v1.json` adds actual word-width
reinterpretation to the existing dense cell-layout theory. It proves31 statements,
including four diagnostics, and gives seven retained records typed partial evidence.
It does not close the Bitcast family or any whole benchmark record.

## Storage and graph meanings

`BitPacking.lean` represents physical words as bounded `Fin cells → BitVec width`
functions and complete bit streams as bounded Boolean functions. `flatten` reads
actual word bits; `inflate` builds actual words using Lean/Std's little-bit-first
Boolean-list constructor. The within-word order is explicitly least-first or
most-first and is independent of the tensor's minor-to-major cell layout.
The bit position decomposes into its physical cell and within-word position using
the existing finite-product maps, whose inverses are proved independently.

Both round trips are proved. Equal total storage bits permit `repack` to change
word width and cell count. That size condition is independent of data values;
the theorem does not assume the desired bit equality. Repacking composes across
arbitrary intermediate widths, cell counts and bit orders. The development is
total even at mathematical width zero; this is not an admission of a machine
primitive with zero bit width.

`physicalConvert` writes input words through the actual existing dense-layout
encoder, repacks their bit stream, then reads the result through its own output
layout. Every legal untiled dense permutation and finite rank is quantified.
Composition cancels the actual intermediate write/read pair. At equal widths
and bit orders, a separate theorem identifies this operation with the pre-existing
independently defined cell Bitcast. Same-cell composition, identity and a pure
Unary sandwich are proved for arbitrary data types and scalar maps, without
numerical assumptions. A logical row-major variant also has identity/composition
proofs; the physical model retains the layout explicitly.

`splitLast` adds the actual trailing width-ratio dimension; `joinLast` removes it.
Their complete element/storage-bit counts are derived from the supplied shape
and ratio. Both use actual standard dense layouts and word repacking, not an
operator defined to return the desired source value. The inverse graph proofs
include scalar input, empty dimensions, zero ratio and mathematical zero width.
Source-facing primitive-width and ratio admission remain separate.

For example, stored bytes `[0x12,0x34]` join to `0x3412` under least-first order
and `0x1234` under most-first order. Numerically extending the first byte gives
`0x0012` and cannot replace packing both bytes. Changing a matrix's row-major
output layout to column-major can also change its logical values even with an
identical logical shape. Finally, `0*8 = 0*16` does not imply `8 = 16`.
Inferring equal element widths from equal total bits needs a nonzero cell count.
All four observations have kernel-checked refutations and normally rejected false
propositions. They do not establish an external optimizer bug.

## Retained labels and open mathematical partitions

| Candidate record | Current core evidence |
| --- | --- |
| `HandleBitcast/unary-sandwich` | Actual same-cell pure Unary sandwich |
| `HandleBitcast/compose-stage` | Arbitrary dense intermediate cell view cancels |
| `HandleBitcast/compatible-stage` | Identical dense storage view is identity |
| `HandleBitcastConvert/compose` | Actual stored-word/dense-layout composition |
| `HandleBitcastConvert/compatible` | Identical width, order, shape and layout is identity |
| `HandleBitcastConvert/same-physical-shape` | Same-width cell-Bitcast bridge; guarded width inference |
| `HandleBitcastConvert/last-contiguous-axis` | Derived actual split/join shape and inverse graphs only |

The last row is not a proof of the entire proposed replacement by a storage
Bitcast. Primitive datatype encodings, storage versus logical widths, padded/
tiled storage, other packing conventions, memory spaces/alias/control observations
and dynamic shapes need explicit models or adapters. Concat packing is also open.
Raw binary32 controls do not prove every scalar encoding adapter or floating-point
numerical conversion. Retained source labels supply benchmark provenance; no
source guard is imported as a proof assumption and no new source analysis is done.
Independent statement and complete record-partition reviews remain pending.

## Reproduction and accounting

```sh
python3 tools/check_theory.py
python3 tools/check_bit_packing.py
python3 tools/mathematical_ledger.py
python3 tools/workload_formulation_audit.py
```

Run these stages in order: the ledger consumes the replay report. The validation
archive preserves an initial dependency-order failure, its diagnosis and the
successful rerun. That failure is an operational mistake, not evidence of proof
search difficulty.

An independent Python oracle packs words into mathematical integers, extracts
masked chunks and materializes arrays in their declared physical orders. Lean
agrees on4127 rows:1368 buffer profiles,384 split/join shape profiles,640 original
word and1120 split/arbitrary-word observations,64 layout profiles/512 output
observations,32 pure cell-map values and seven binary32 stored-bit round trips.
Controls include widths0/1/3/4/8/16/32, empty storage, scalar and rank1–3 shapes,
rank-changing ratio axes, mixed row/column-major intermediate layouts and both
bit orders. Generality comes from the proofs, not these finite development
controls; this is not a held-out independent semantic audit. All148 curated
mathematical tests pass.

The extension adds314 custom Lean lines: S69/H68/R152/A1/C24. Totals are727 theory
statements,987 ledger declarations and12341 custom Lean lines, with four library
integration results separate. Lean/Std supplies word construction/extensionality;
the existing project finite-product and dense-layout inverses are reused. FloatLib
is used for stored-bit controls. No dependency pin changes or imported rewrite
solutions are introduced. Operational fixtures/harness sizes are separate from
core L; no minimum-size, library-ablation or blind-discovery claim is made.

Catalogv11 preserves all488 retained IDs;206 retain only proposal worksheets.
States are215 needing formulation/domain work,151 partial and122 carrying declared
value families. The six complete declared families remain397 profile units.
Whole-record closure remains zero; mathematical N/F and the final workflow verdict
remain open. All638 statements beyond the reviewed89 require independent review.
Code correspondence remains future work. The accepted snapshot is finalized after
development at its first commit, rather than preregistered as a discovery trial.
