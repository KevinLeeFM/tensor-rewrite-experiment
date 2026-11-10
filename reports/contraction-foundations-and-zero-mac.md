# Logical contraction, native casts and the zero-initialized MAC boundary

XLA e58e523b11f1fde802a493a776d158007486e1bf; Lean 4.35.0
(eb6cafb7290e8bd5f2937522d8d804f58f02bafc), Std only. Canonical pass unchanged.

The development now defines a general ordered Dot contraction. Batch, left-free,
right-free and contracting axis groups have arbitrary finite rank and extent;
operand permutations carry both inverse laws. Bounded output/contract coordinates
construct actual operand coordinates, rather than assuming opaque index maps.
Each contraction fiber is enumerated in dim0-major order and folded from an
explicit initializer. Operand product/conversion and final conversion are explicit
parameters; no reassociation, commutativity or arbitrary initializer identity is assumed.

## General proofs and source relation

`TensorRewrite/Pilot/ContractionRules.lean` proves four empty cases: contracted
fiber empty, output empty, lhs empty, rhs empty. The result is the finished
initializer, not an unexplained scalar zero. Two further laws remove a contraction
with no contracted axes: a single product remains, provided adding the initializer
is invisible after finish; a stronger left-identity premise suffices as a corollary.
Six support lemmas establish coordinate projections, fiber length, the singleton
no-axis fiber, and emptiness implications from either operand.

Source candidates are `HandleDot/empty` and the four
`RewriteAsMultiplyDotWithZeroLhsContractingDim/casts-00/01/10/11` cases. These
are overlapping proof links, not six additional accepted source rewrites.
`census/contraction-contract.json` pins exact source slices for normalization,
helper construction, guards, slow evaluator MAC and casts/dispatch. Type/precision,
actual dimension-list extraction and ordering, finish/initializer correspondence,
signed-zero permissions and graph/API effects still require review.

## Native controls and independent calculation

`reports/contraction-replay-v3/result.json` archives 19 profiles × 3 execution
modes (control, initialized exact handler, whole pass), 57 runs in total:

- Four s32/s8 input combinations with s32 preferred result.
- Both batch-axis placements, a rank-four output and scalar operand.
- Zero contraction extent, zero free extent in either operand and empty outer output.
- A nonempty matrix contraction with rewriting enabled, plus disabled-option and
  layout-sensitive controls. The matrix computes all three products and remains
  unchanged, isolating the no-contracting-dimensions guard.
- Binary32 negative/positive zero, finite negative products and disabled-option zero.

All graphs verify and all expected transformations/retentions occur. The 45 integer
mode/profile observations agree with Python's independent Cartesian-coordinate
reference and 15 Lean vectors. Lean computes original s8/s32 storage conversions,
s32 result conversion, signed 64-bit multiply/add and final s32 narrowing. The
replacement multiplies in s32 directly. Inputs are small/nonuniform, with negative
values in cast cases; this batch does not add new overflow coverage.

A direct handler requires the visitor's computation state. The diagnostic
subclass first invokes public Run with only HandleDot suppressed, checks both
unchanged status and unchanged graph text, then invokes the original HandleDot.
It does not access private fields or modify the canonical implementation.
The verifier permits the mixed types/preferred result; the evaluator converts
inputs to result type before Dot. The helper also converts operands before Multiply.

## Signed-zero observation and its limits

All FP cases use explicit slow HloEvaluator, round-to-nearest, disabled CPU fast
math and NaN/Inf honoring. With no contracting axes, the original evaluator
performs one multiply-accumulate starting from positive zero. For lhs [-0,+0]
and rhs [1,2,3], original output is six positive zeros; transformed output starts
with three negative zeros. Both handler and pass reproduce this bit difference;
numeric equality holds. Disabled-option and positive-zero controls retain all bits.

`ZeroMacProfile.lean` states only necessary signed-zero/unit product and mixed-zero
addition conditions for this one MAC. Four empty-axiom certificates establish
consistency, original positive zero, incompatibility of replacement negative zero,
and distinct bits. This is a deliberately partial numerical profile, not a complete
IEEE arithmetic formalization or an adopted backend observation contract. It is
an evaluator/bit-observation diagnostic. It is not counted as an accepted source
refutation or evidence that all HLO implementations must preserve these zero bits.

## Accounting and validation

| Category | Previous | Added | Current |
| --- | ---: | ---: | ---: |
| S, semantics | 622 | 84 | 706 |
| H, shared proofs | 817 | 49 | 866 |
| R, rules | 643 | 48 | 691 |
| A, integration | 27 | 3 | 30 |
| C, certificates | 236 | 18 | 254 |
| Total custom Lean | 2345 | 202 | 2547 |

77 value laws and 86 support lemmas are kernel checked. Tests, audits and all
non-Lean tooling remain separately accounted. No source rewrite is accepted;
semantic N/F remain unfrozen. Shorter general proofs do not close source mapping.
The four new certificates have no axioms; older axiom gates are preserved.

The pilot and 57 tool/evidence tests pass. Mutation controls reject omitted cast
or axis rows, a wrongly enabled matrix rewrite, erased signed-zero differences,
constructor-only visitor initialization and scope promotion. A Lean negative
control rejects replacing an actual two-term contraction (11) by its first product
(3). Exact result tables and hashes remain with the immutable native archives;
prior v1/v2 observations are preserved. v2 adds a matrix with the option disabled;
v3 enables it to isolate the contracting-axis guard.

Final checkpoint and fresh replay status: see `initial-checkpoint.json` and
`contraction-clean-replay.json`. The independent frozen-baseline review runs
separately and excludes the signed-word and contraction extensions.


The first clean snapshot (`contraction-pilot-v1.zip`, 2546 lines) is preserved;
final line wrapping adds one code line in S. `contraction-pilot-v2.zip` and the
current clean-replay report identify the final 2547-line source. This formatting
change preserves theorem statements and prior axiom sets.

Independent review of the earlier frozen census packet found omitted Python
tests (discovery incorrectly succeeds with zero tests) and a missing older native
archive required by a checker. These limit reproducibility of that packet; they
are not evidence of incorrect Lean proofs. The live checkpoint now rejects
missing/fewer-than-57 discovered tests. `tools/freeze_review_packet.py` includes
all test sources and older-schema native archives; a replacement packet must
be frozen and checked separately. The original packet remains unchanged.


Completed validation: full live checkpoint (57 tests) and final fresh Lean replay
pass. Final snapshot SHA256: cce69b843ad6113b85338f2732247733f4c4c9c86e7b958ce776d24294e509aa.
The independent v1 review now dispositions20 targets and reads43/58 Handle-prefixed
bodies, with15 bodies/103 other functions/all487 semantic cases explicitly open.
Its result and resolution are under `reviews/`; no failed baseline Lean proof or
new axiom was found. Corrected packet v3 passes57 Python tests and the missing
historical-native checker in a fresh extraction. Its Lean files match the final
clean snapshot byte for byte. These are integrator packaging checks, not an
independent review of the later extensions or a whole-file verdict.
