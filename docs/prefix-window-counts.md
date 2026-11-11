# Ordered cumulative windows and exact integer count domains

A cumulative window with one scan axis is now proved equal to its actual ordered
input prefix, with leading padding retained unless the initializer is fixed by
that padding. The scan axis can occur anywhere in an arbitrary positive-rank
tensor. Retained unit-window axes have arbitrary positive strides, with their
sampled input coordinates and output bounds derived from the window geometry.

## Geometry and the direct target

For scan extent n, `prefixAxis` uses kernel extent n, unit stride/dilations, no
reversal, signed low padding n-1 and high padding0. Its output extent is n even
at n=0: signed low padding is then -1. Empty input/output/kernel profiles belong
to the declared model without asserting external IR admission. A scalar without
a scan axis is outside this plan, rather than silently treated as a cumulative case.

`Plan.scan` permits an arbitrary trailing retained shape/stride array; `Plan.keep`
adds retained axes before it. Each retained output samples original coordinate
output*stride, and `retained_bound` proves that coordinate is legal. The retained
output extent is max(floor((extent-1)/stride)+1,0). It need not equal input extent.

`prefixValues` is defined independently by original input coordinates: fix the
retained coordinates at their sampled positions, then enumerate scan positions
0 through i at scan output i. `kernel_enumerate` identifies the actual arbitrary-rank
kernel enumeration with the increasing scan range. `sample_valid` and
`sample_invalid` derive its occupied and absent positions. `values_prefix` proves:

`window values = replicate(n-1-i,padding) ++ actual input prefix[0..i]`.

This is an equality of complete ordered lists, not only a commutative-sum result.
Any operation and initializer can fold that list. `reduce_prefix` discards the
leading padding only under `operation initial padding = initial`; a global
neutral-element law or associativity is unnecessary. `nonfixed_padding_refuted`
checks a fold result4 versus a proposed prefix-only result2 when this law fails.

## Exact and fixed-width arithmetic

For `AddMonoid`, a constant value produces initial+(i+1) acting additively on the
value. For exact `Semiring`, a zero-initialized sum equals
`Broadcast(value) * (Iota(scan axis)+1)`, with the natural coordinate cast into
the semiring. This uses explicit algebraic laws; rounded floating addition is
not supplied with this structure.

For every `BitVec width`, repeated modular addition equals modular multiplication
by the same-width count. `word_prefix_product` therefore proves the actual window
equal to Broadcast(value) times same-width Iota+1, even when arithmetic wraps.
The32/64-bit corollaries instantiate this contract without a hidden no-overflow
premise. They do not establish arbitrary intermediate-width conversion graphs.

The exact observation domains are also derived for the actual prefix-count
reduction, not merely assumed about a replacement:

- Unsigned count equals the mathematical natural count iff count < 2^width.
- Signed count equals that nonnegative count iff 2*count < 2^width.

Width0 is included as a mathematical word model; no external dtype admission is
claimed. `word_count_overflow_refuted` checks actual two-bit prefix counts giving
unsigned0 at count4 and signed-2 at count2. `signed_width_boundary_refuted` checks
negative interpretations at the32/64-bit positive thresholds. These are contract
certificates, without compiler-source or failed-proof-search conclusions.

## Validation and measurement

Thirty-four new statements comprise17 shared geometry/list/arithmetic results,
14 prefix/product/observation results and three certificates. New custom Lean is
466 lines: S66/H241/R134/A1/C24. Semantic operator definitions have their own S
modules; reusable indexing/arithmetic proofs are H. Total6429
(S1456/H2528/R1841/A83/C521),264 theory/524 ledger declarations; four integration
theorems are separately audited. Pinned Mathlib/Std facts are reused and disclosed,
not counted again. No admitted proof or new project axiom is accepted.

The independent Python oracle enumerates original tensor coordinates and filters
the inclusive prefix at the retained sampled coordinates. It separately enumerates
the original window's positions. All726 small profiles/1290 outputs agree on full
lists, nonassociative folds, neutral-prefix folds, exact counts and modular products.
Forty-five conversion controls include width0 and32/64-bit boundary values.

The first small matrix used retained extents0..2, so stride2 admitted only output0.
The separate `prefix-window-stride-controls-v1` addendum addresses that control
coverage gap without changing frozen v1 sources/results. Four chosen nonzero
stride outputs before/after/on both sides of the scan observe prefixes[5,6],
[3,6], [21,24,27] and[21,24]. These finite controls supplement the universal proof.
Standalone interpolated IO fixtures are reported by physical length outside the
primary accepted proof-code language. All58 focused tests pass; see
`reports/prefix-window-validation-v1/` and the milestone JSON for exact fixture sizes.

Sources are pinned in `census/prefix-window-v1.json` and
`census/prefix-window-stride-controls-v1.json`; complete results are in
`reports/prefix-window.json` and `reports/prefix-window-stride-controls.json`.

## Remaining workload

The successor `census/reduction-window-domains-v3.json` preserves all31 records
and earlier worksheets. Four cumulative labels receive partial exact/word core
bindings. Twenty-six window records have partial core associations; four broadcast
alternatives and one singleton-tuple record still lack those associations.
All488 records remain364 unformulated/112 partial/12 carrying the earlier logical
value family. Zero whole records close; mathematical N/F and the verdict remain open.

Literal/wrapper recognition, cross-width count conversion, other target numeric
types, rounded accumulation versus multiplication, unit-axis attribute normalization,
flags/representation and complete per-record domains remain open. The new34
statements await independent review;175 statements are outside the original reviewed89.
The full mathematical campaign continues. Code correspondence stays future work.
