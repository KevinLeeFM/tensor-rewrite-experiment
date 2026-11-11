# Complete declared exact-arithmetic value profiles

The closed family has 43 rule/order instances: 19 fixed cases and 24 cases retaining
matched operand-order bits. One generic theorem proves all of them for arbitrary
finite tensor rank, extents and values in any actual `CommRing`. Four checked
instantiations give exact integers, exact reals, exact complex values and modular
words at every width, including zero. These are 172 declared value-profile units,
not 172 independent theorem bodies or a whole-workload denominator.

The trees retain actual shared inputs, Add/Subtract/Multiply/Negate nodes and
predicate conversion/selection. Addition and multiplication association retain
inner/outer order; four-factor regrouping retains all eight orders; common-factor
extraction retains all four. The complete enumeration and unique reporting keys
are kernel checked. Constant recognition is unnecessary for these stronger exact
value identities. Pure context congruence is checked; effectful evaluation is not
supplied by that theorem.

Five further corollaries derive actual bounded Broadcast graphs for subtraction,
sum rebuilding, subtraction/sum rebuilding, product rebuilding and a uniform scalar
factor. Bounds and extent witnesses are explicit. The uniform-factor corollary
requires an actual scalar factor and remains scoped partial evidence for its
candidate record. It is separate from the closed pointwise rule enumeration.

## Numerical boundary and controls

The evaluator accepts explicit scalar operations, so the same typed trees also
have a separate binary32 interpretation. Three kernel certificates refute exact-
ring shortcuts under stored-bit observations: addition reassociation gives zero
versus one; product reassociation gives zero versus the smallest subnormal; positive
infinity times zero gives NaN rather than the zero replacement. The first two
finite controls agree with the existing exact-rational independent oracle. NaN
classification is checked without assuming a particular payload policy.

The binary32 interpreter uses FloatLib add/subtract/multiply and explicit stored-sign
negation; the three certificates use add/multiply. Flags are not observations here.
The checker also requires actual rejection of a `CommRing Binary32` instance.
The exact-family proof does not establish all other IEEE profiles or optimizer
option permissions. Scalar dtype, rounding, exceptional, effect, schedule and
physical observation partitions remain explicit future mathematical work.

All 28,638 integer/word scalar controls and 480 actual Broadcast controls agree
with an independent expression/coordinate evaluator. Word widths zero through two
exhaust all input quadruples and both predicates; wider sampled words and signed
integer boundaries supplement them. Graph controls include scalar, empty, retained
and permuted-axis Broadcasts and all matched sum/product orders. Exact real and
complex tracks have general kernel proofs, not runtime controls over every value.
The two fixture files have 121 and 6 physical lines, disclosed outside primary LOC.

## Workload refinement and replay

The family gives 33 retained candidate records complete declared pure-value
profiles. A 34-record worksheet also carries the Broadcast-factor corollary and
remaining partitions. Catalog v4 preserves every one of the 488 retained IDs;
340 records now have only unreviewed proposal worksheets. No source guard or option
label is adopted as an algebra law. Candidate label correspondence remains
uncertified and no whole record closes.

Run `python3 tools/check_theory.py`, `python3 tools/check_arithmetic_family.py`,
`python3 tools/mathematical_ledger.py` and `python3 tools/workload_formulation_audit.py`.
The model/profile packet v1 is preserved at commit `51e5dd7`. The active manifest
`census/arithmetic-values-family-v2.json` pins the identical Lean model and repairs
recognition of Lean's structured diagnostic format for the expected Float-ring
rejection. Failed first-attempt logs remain archived. No mathematical statement,
dependency or profile denominator changed in that repair. V1 replay uses its
snapshot commit; current validation uses v2.

Nineteen checked statements add 313 custom Lean lines: S140/H0/R135/A2/C36. Totals
are 463 theory statements, 723 ledger declarations and 9447 custom Lean lines
(S2184/H3645/R2713/A95/C810), with four integration results separate. Mathlib's
proved `BitVec` ring instance and ring normalization supply reusable algebra;
imported code is separately disclosed and all new semantics/adapters enter LOC.
There is no matched baseline ablation establishing a numerical library benefit yet.

Complete declared family-profile units total 193. Of 488 records, 346 need further
formulation/domain work, 96 are partial and 46 carry value families. Whole-record
closure remains zero; N/F and the final workflow verdict remain open. The 374
statements beyond the original reviewed 89 await independent statement review.
Exact accepted logs/metrics are in `reports/arithmetic-family-milestone-v1.json`.

All 108 curated mathematical tests pass. The stale two-family regression assertion
was updated for the new third family; its failed run remains preserved alongside
the earlier diagnostic-format failure. Final accepted commands are archived in
`reports/arithmetic-family-validation-v2/`.
