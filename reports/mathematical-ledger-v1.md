# Mathematical obligation ledger and exact contraction algebra

Active scope is mathematical tensor-rewrite verification. Code correspondence,
C++ extraction/inspection and native pass investigation remain deferred. This
milestone reads retained benchmark JSON, checks Lean declarations and extends
mathematical contraction theory; it performs no new implementation correspondence.

## Frozen corpus versus mathematical obligations

`census/mathematical-corpus-v1.json` freezes the identities and hashes of ten
retained benchmark batches, totaling488 records. The manifest is immutable under
its version: re-freezing v1 is rejected. Every input ID and abstract LHS/RHS is
retained, including unresolved aliases and non-value records. Retained guard notes
are explicitly unreviewed benchmark annotations, not adopted theorem assumptions.

The488 is a benchmark-record count, not a canonical mathematical obligation
count. One record may need several dtype/shape/observation partitions; helper or
bookkeeping records may need a scope disposition. No record is dropped because
its formulation or semantics is difficult. Mathematical N and family count still
need explicit formulation and review. This does not require reintroducing the
deferred code-correspondence audit.

`census/mathematical-ledger.json` currently records:

| Evidence category | Registered declarations |
| --- | ---: |
| Existing value laws, including logical nested slicing | 78 |
| Shared support lemmas | 90 |
| Pure graph-context identities | 12 |
| Fixed-schedule effectful-context identities | 12 |
| Refutation or diagnostic certificates | 38 |
| New library-backed theory, including this milestone | 12 |
| Distinct registered declarations | 242 |

This is the initial selected evidence inventory, not a claim to enumerate every
helper/certificate in the repository. Historical evaluator-only diagnostics and
additional unregistered auxiliary results remain in their original artifacts.
Every registered declaration is checked in Lean with its full type and transitive
axioms. All require only standard Lean axioms. The audit log and generated audit
module are hash-linked. Independent mathematical statement review remains open.

Seventy-four benchmark records have candidate evidence labels and414 have none.
Candidate labels are retained historical associations, not newly certified
correspondence or proof of complete semantic coverage. All488 records remain open
at whole-record level; model proofs are genuine kernel-checked results under their
own declarations, while missing partitions prevent a whole-record verdict.
No242/488 or74/488 percentage is presented as verified rewrite coverage.

The generator and tests reject changed corpus hashes, overwriting the frozen
manifest, unknown benchmark labels and attaching unchecked declarations as checked
evidence. Even checked model evidence does not close a whole record automatically.
No native evidence validation or C++ processing occurs in these commands:

```sh
python3 tools/check_theory.py
python3 tools/mathematical_ledger.py
python3 -m unittest discover -s tests -p test_mathematical_ledger.py -v
```

## New general contraction proofs

`TensorRewrite/Theory/ContractionAlgebra.lean` proves two mathematical identities:

```
Dot(x+y,z) = Dot(x,z) + Dot(y,z)
Dot(x,y+z) = Dot(x,y) + Dot(x,z)
```

Both use the existing Plan and dotTensor definitions, not a replacement scalar
Dot abstraction. Batch/free/contract ranks and extents are arbitrary; the operand
axis plans are bijections, and empty outputs/fibers are covered. Scalar operations
form a Semiring, accumulation starts at0, and finish is identity. Multiplication
need not commute. The proofs preserve the modeled axis/index construction and
use distributivity plus finite-list summation. FloatLib binary floating operations
are not silently given these algebraic assumptions.

The previous exact finite-sum and floating-negation laws remain included. There
are now12 statements in the library-backed theory target: four negation laws,
six finite-sum/coordinate/fold results and the two new contraction laws.
This is a theorem count, not12 distinct benchmark rewrites.

## Artifact burden and remaining gates

The new contraction module adds29 category-R code lines; its root import adds
one category-A line. Total custom Lean is2907 lines: historical pilot2763,
library integration33, and library-backed theory111. The combined categories are
S776/H978/R746/A70/C337. Test/audit and Python ledger code are counted separately;
imported Mathlib/FloatLib code and reused lemmas remain attributed.

Build,12-theorem theory axiom audit,242-declaration inventory audit and three
mathematical-ledger boundary tests pass. This is not a new clean independent
replay of the complete campaign. The old source-acceptance fields and historical
packets are unchanged and do not gate mathematical acceptance.

Next formulate the complete mathematical obligation partitions and scope
annotations, adopt reviewed model contracts, finish the diverse pilot, attempt
the full workload and diagnose residuals under the original experimental protocol
as amended by the user. Neither a positive nor a negative full-workflow result
is established by this milestone.
