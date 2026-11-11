# Word remainder graphs and collective-domain diagnosis

This milestone broadens the mathematical campaign beyond windows. Twenty-eight
new statements add240 custom Lean lines (S17/H40/R151/A2/C30), reusing Lean/Std
word arithmetic, Mathlib tactics and the existing FloatLib pin. There is no new
dependency or toolchain revision. Inputs are frozen in `census/remainder-v1.json`.

## Exact and finite-width remainder

`Remainder.integer` explicitly means `Int.tmod`, truncating toward zero.
`integer_nested_tensor` proves `Rem(Rem(x,d),d)=Rem(x,d)` pointwise. The same law
holds for actual unsigned word remainder and `BitVec.srem` at every width and
for arbitrary tensor rank/extents. These library operators are total at divisor
zero, returning the dividend. This is a disclosed model choice, not a statement
about external undefined, trapping or floating division-by-zero behavior.

`unsigned_mask_tensor` proves remainder by a represented `2^k` equals bitwise
And with the actual same-width divisor-minus-one mask, for `k<width`.
`signed_mask_tensor` proves the actual Select/Negate/And/sign-correction graph
for a positive signed power, `k+1<width`. Its magnitude negation stays modular.
Signed minimum therefore needs no special repair: the proof uses the actual
unsigned magnitude remainder in the library's signed operator, not an assumed
representable positive signed absolute value.

The Iota definition encodes an actual bounded axis coordinate at the selected
word width. An unsigned Iota is unchanged by remainder when axis extent is at
most the decoded divisor. The signed case additionally requires a clear divisor
sign bit; the bounds derive Iota's nonnegative signed representability. Empty
axes, other empty dimensions and the degenerate width-zero model remain explicit.
No external width-zero primitive format is asserted.

Removing a divisor addend before remainder has separate unsigned/signed domains.
For every actual coordinate i and decoded divisor d, unsigned addition requires
`i+d<2^width`. Signed addition additionally requires a nonnegative divisor and
`2*(i+d)<2^width`. Both operand orientations are proved. These sufficient bounds
are independent mathematical assumptions; no retained C++ guard is adopted as a
proved implication. Arbitrary-width universal proofs are distinct from controls.

Three checked four-bit examples expose weakened contracts:

- Signed `-5 rem 4` is `-1`; omitting sign correction yields mask value3.
- Unsigned `(7+10) rem 10` wraps before remainder and gives1, while `7 rem 10` gives7.
- Signed `5+3` fits the unsigned width but crosses the sign bit: its remainder by3
  is `-2`, while the original coordinate's remainder is2.

## What the installed floating library supplies

The FloatLib import has actual binary32 addition and multiplication, enabling a
checked stored-bit counterexample to fixed-order uniform summation by multiplication.
Ten additions of encoding `0x3dcccccd` from positive zero produce `0x3f800001`;
multiplying that value by exact ten (`0x41200000`) produces `0x3f800000`.
`UniformSum.binary32_uniform_product_refuted` proves both exact results.

This is a **fixed-order bit-equality diagnostic**, not a refutation of every
permitted collective reduction schedule or an external compiler bug claim.
An independently admitted communication/schedule/refinement contract remains
missing. A uniform modular-word list-fold law is reused separately from
`PrefixWindow.word_replicate_fold`; it does not establish group or scatter geometry.

The installed FloatLib IEEE `remainder` uses a nearest-integer quotient. Its local
`Floats/THEOREMS.md` explicitly distinguishes a sign correction corresponding to
C's `fmod`. We have not instantiated a truncating floating remainder adapter or
its exceptional-value/flag contract. Importing the nearest-quotient operator under
the truncating name would prove the wrong target. The floating nested-remainder
partition therefore remains open despite the exact/word proofs.

## Evidence and remaining workload

The17-record `collective-rotation-mathematical-domains-v1.json` gives each retained
case a target, explicit premises, core evidence or concrete missing-model diagnosis.
Six remainder records, the uniform modular-fold case and the floating diagnostic
have core associations; all remain partial. The other records identify missing
collective replica/group/output maps, idempotent scalar/initialization domains,
helper-dependent targets, cyclic rotation indexing or n-ary Broadcast naturality.
This is formulation/dependency work, not a completed full campaign sweep or N/F.

Run `python3 tools/check_theory.py`, `python3 tools/check_remainder.py`,
`python3 tools/mathematical_ledger.py` and `python3 tools/workload_formulation_audit.py`.
The archived replay and75 focused tests pass in `reports/remainder-validation-v1/`.
Independent integer arithmetic checks all5,461 operand pairs at widths0 through6,
361 signed integer pairs,2,350 bounded Iota profiles/2,368 outputs and30 finite
binary32 controls against an exact rational oracle. Controls include signed minimum,
negative/zero divisors, width zero, empty tensors, sign correction and both kinds
of overflow. The70 physical interpolated IO fixture lines are outside primary
lexical proof-size counts. Mutations of signs, ranges, certificates, dependencies
and coverage claims must be rejected.

The new whole-corpus audit reconciles all488 retained IDs with the current explicit
domain worksheets. The window worksheet refines reduction and is not counted twice.
Only108 records have such a worksheet;380 lack one. Seventy-three records have
proof evidence but no domain worksheet, showing why theorem counts cannot substitute
for formulation. Worksheet presence itself does not prove completed formulation.

| Retained batch | Records | With domain worksheet | Without |
| --- | ---: | ---: | ---: |
| Arithmetic |85|0|85|
| Collective/rotation |17|17|0|
| Convolution |31|31|0|
| Dot |44|0|44|
| Layout |30|0|30|
| Reduction/window |60|60|0|
| Scalar/control |55|0|55|
| Shape |58|0|58|
| Simple |51|0|51|
| Tensor indexing |57|0|57|

The frozen worksheet catalog and `reports/workload-formulation-audit.json` retain
this gap explicitly. Next complete the missing batch formulations and mathematical
domains, then continue all-case proof work, residual interventions and independent
reviews. Do not call this audit a completed initial proof sweep.

Current totals:341 theory statements,601 ledger declarations, four separately
audited integration results and7,547 custom Lean lines (S1711/H2974/R2152/A88/C622).
Complete declared value profiles remain21. Of488 retained records,351 need
formulation/domain partitions,124 have partial evidence and13 carry declared value
families. Whole-record closure is zero. The252 theory statements after the original
reviewed89 still await review. Mathematical N/F and the final positive/negative
workflow verdict remain unresolved; code correspondence is user-deferred future work.


The later [whole-workload proposal milestone](workload-formulation-proposals.md)
preserves the108/380 audit above under catalog v1 and introduces catalog v2 with
all488 records covered by worksheets. Its380 new rows are unreviewed proposals,
not new accepted Lean statements or whole-record proofs. The theoretical/proof
counts above do not increase merely from adding those worksheets.
