# Exact logarithm and square-root domains

The retained scalar-control records motivate four mathematical targets. We split
Log(Exp(a)) into real and principal-complex profiles, giving five profiles below.
Benchmark labels identify provenance; their guards and source correspondence are
not adopted as proof premises. All operations in this milestone are exact
mathematical functions from pinned Mathlib, with its principal branch conventions.

| Target | Scalar domain | Checked result |
| --- | --- | --- |
| Real log(exp x) | Every real x | Equals x |
| Principal-complex log(exp z) | −π < Im z ≤ π | Equals z iff this condition holds |
| Real log(sqrt x) | x > 0 | Equals (1/2) log x under this sufficient domain |
| Real sqrt(x*x) | Every real x | Equals abs x |
| Principal-complex sqrt(z*z) | Im z = 0 | Equals the embedded magnitude iff this condition holds |

The two complex iff statements derive necessary as well as sufficient conditions.
For log/exp, necessity follows from the principal logarithm's imaginary range.
For sqrt-square/magnitude, squaring the equality and comparing the real part
with the norm-square identity forces the imaginary part to vanish. Sufficiency
uses the real-axis square-root law. Five tensor theorems lift these results
pointwise to arbitrary finite ranks and natural extents.

There are two checked counterexamples, counted as C: at z=2πi the principal log
of exp z is zero; at z=i, sqrt(z*z)=i while the magnitude is one. These refute the
unguarded mathematical identities. They do not refute an implementation under a
different fast-math, branch or approximate-observation contract.

The real log/sqrt result deliberately requires strictly positive values. It does
not use Mathlib's totalized logarithm at zero to model an executable logarithm.
Neither necessity of positivity nor complex log/sqrt is proved in this milestone.
Rounded transcendental functions, signed-zero branch behavior, infinities, NaNs,
status flags, tolerances and fast-math permissions remain separate obligations.
The square-root complex absolute value means real norm embedded into complex.

## Reproduce

```sh
python3 tools/check_theory.py
python3 tools/check_scalar_domains.py
python3 tools/mathematical_ledger.py
python3 -m unittest discover -s tests -p test_scalar_domains.py -v
```

The 14 new registered statements comprise two helpers, ten positive/domain/tensor
results and two counterexamples. Eight additional symbolic controls check actual
branch endpoints, witness expression values, negative-real magnitude, empty
shape vacuity and the observable imaginary-unit mismatch in a rank-zero tensor.
They are checked proof fixtures with audited standard axioms, measured separately;
no host floating-point oracle or unchecked computation is used.

New custom Lean is118 lines: H20/R79/A1/C18. The project total is4283, with
S1131/H1517/R1191/A77/C367 including certificates. The theory target has103
registered statements; the broader ledger audits363 declarations. The four
library integration theorems remain separately audited. Imported library sources
are disclosed dependencies, not counted as new proof code.

The accepted input pins are `census/scalar-domains-v2.json`; exact results are in
`reports/scalar-domains.json`. The first v1 fixture needed an explicit pi-positive
fact after simplification; its failed source snapshot and classification are
preserved, and v2 fixes only that fixture elaboration. Mathematical theory
statements did not change between those versions. An integration regression also
needed to select convolution models rather than assume they were the whole model
list; first-attempt logs are retained. These are not theorem refutations or
proof-search difficulty observations.

All488 retained records remain:401 need formulation,75 have partial evidence,
and12 carry the previously declared logical-value family. Zero whole records
are closed and the mathematical denominator remains open. The earlier independent
semantic review covers the old89-statement foundation; these14 new statements
await independent review. Code correspondence is future work.
