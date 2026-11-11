# Exact division and numerical value graphs

The numerical extension proves arbitrary-rank, arbitrary-extent tensor equations
for division, exponentials, powers, square roots and reciprocal square roots.
Its 53 statements include five exact counterexamples. Thirty-one retained candidate
records gain concrete typed evidence; every whole-record status remains open.
This is a partial mathematical model, not a newly closed workload family.

## Selected operations and domains

Division uses a genuine `Field` instance with inverse zero equal to zero. The
quotient-of-quotients and two nested-division identities hold even with zero
factors under this convention. The actual Broadcast reciprocal/predicate graphs
use bounded axes and extent witnesses, with arbitrary input/output ranks and
permuted axes. These are not machine integer or floating-point division proofs.
The checker requires actual rejection of `Field (BitVec 8)`.

Real functions are Mathlib `Real.exp`, `Real.rpow` and `Real.sqrt`. In particular,
Mathlib real power is the real part of principal complex power: at a negative
base it uses a cosine factor. Square root of a negative real is zero. These
explicit totalizations are part of the declared mathematical model and are not
claims about a rounded `pow`/`sqrt` implementation. Conventional positive log
profiles require strictly positive inputs instead of relying on log-zero behavior.

Complex power is Mathlib principal `Complex.cpow`; complex sqrt is its principal
half power. Both real and complex power use `0^0 = 1`. Reciprocal square root is
explicitly the inverse of the actual square root, with inverse zero equal to zero.
It does not stand for a separately rounded reciprocal-sqrt primitive.

| Graph | Exact real result | Principal complex result |
| --- | --- | --- |
| Exp product/quotient and Exp denominator | All inputs | All inputs |
| Powers zero, one, two, three, minus one, half | All inputs under selected totalizations | All inputs |
| Power of Exp | All inputs | Sufficient input strip `-pi < Im(a) <= pi` |
| Sqrt multiplied by itself | Equals input iff every value is nonnegative | Equals input everywhere |
| Reciprocal Sqrt multiplied by itself | Equals reciprocal iff every value is nonnegative | Equals reciprocal everywhere |
| Rsqrt of inverse square | Equals absolute value everywhere; equals input iff nonnegative | General branch domain remains open |
| Log of Power | Sufficient positive-base profile | At nonzero bases, selected-product equality iff its imaginary part lies in `(-pi, pi]` |
| Log of Rsqrt | Sufficient positive-input profile | General branch domain remains open |
| Power denominator replaced by negated exponent | Sufficient nonnegative-base profile | All inputs |
| Rsqrt of reciprocal | All inputs under selected totalizations | Refuted on negative real axis |

Every equation is kernel checked. The sufficient profiles do not certify their
complements. The real root/sign iff results and complex log-power strip iff are
exact characterizations within their stated models; the latter still requires
pointwise nonzero bases. Empty tensors are admitted, and pointwise conditions
correctly become vacuous there. No nonempty-domain assumption is added.

## Refutations and controls

Five checked scalar witnesses reject dropped premises: real sqrt-square at -1;
real inverse-square rsqrt at -1; real negative-base reciprocal power at base -1,
exponent 1/3 (two versus one half); complex reciprocal sqrt at -1 (-i versus i);
and power of complex Exp at one complete imaginary period and half exponent
(one versus minus one). These are mathematical domain diagnostics, not optimizer
bug claims or proofs about allowed fast-math behavior.

The independent rational evaluator covers all 625 input quadruples from
`{-2,-1,0,1,2}`, comparing 5625 scalar expression pairs. It includes zero
numerators/denominators and signed values. Forty-eight actual bounded Broadcast
value pairs agree with an independent dense-coordinate oracle over five shape/
axis scenarios, including scalar, empty and permuted axes. Ten separate symbolic
controls check zero power, negative cube/half, branch endpoints and empty shapes.
These are development controls, not an independent held-out audit. The two fixture
files have 111 and 5 physical lines, counted separately from primary Lean LOC.

## Replay, versioning and size

Run `python3 tools/check_theory.py`, `python3 tools/check_numerical.py`,
`python3 tools/mathematical_ledger.py` and `python3 tools/workload_formulation_audit.py`.
Active manifest `census/numerical-values-v2.json` pins the four unchanged Lean
modules, controls and oracle. V1 is preserved at preacceptance commit `7862eb4`.
Its first checker expected 33 candidate records although the explicit enumeration
contains 31; V2 repairs that accounting assertion and strengthens domain checks.
The failed preacceptance log is retained. This checker failure is not a false
mathematical theorem or evidence of proof-search difficulty.

The extension adds 325 custom Lean lines: S0/H0/R286/A1/C38. Imported Mathlib
field/analysis results are reused separately from these new lines. No dependency
or toolchain changes were needed and no controlled library ablation was performed.
Current totals are 516 theory statements, 776 ledger declarations and 9772 custom
Lean lines (S2184/H3645/R2999/A96/C848); four integration results remain separate.

Catalog V5 retains all 488 records; 309 still have only unreviewed proposal
worksheets. Current record states are 315 needing further formulation/domain
work, 127 partial and 46 carrying the earlier complete value families. The global
complete declared family-profile count remains 193: this partial numerical model
does not increase it. Whole-record closure is zero, N/F is unfrozen, and the final
workflow verdict remains unresolved. The 427 statements after the original
reviewed 89 await independent statement review. Code correspondence stays future work.
