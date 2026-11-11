# Ordered convolution: a binary32 proof and numerical boundary evidence

**Accounting correction:** The original counts below are retained for history.
MF-01/MF-02 supersede the ledger subtotal and R/C split; see
[the correction record](mathematical-review-corrections-v1.md) and
`census/convolution-ordered-accounting-v1.json`. No Lean statement changed.

Pointwise convolution now equals the existing matrix Dot under an explicit
ordered scalar contract. The proof establishes equality of complete contribution
lists at the same numeric positions, then preserves the same fold, initializer,
product and finish. It uses no scalar algebraic law. Operand, accumulator and
result types may differ. The Semiring specialization is proved equal to the
previous exact model.

The pinned FloatLib binary32 specialization preserves stored values for all
operands under the shared separate multiply/add schedule. A second theorem
reuses FloatLib's scalar reference equalities to prove whole-model reference
agreement. Arbitrary rank, extents, groups and channel counts remain quantified.
Flags, FMA, changed precision/cast placement, physical layouts and external
backend schedules are separate unverified contracts.

The single-channel theorem retains `finish(add(initial, product))`. Two concrete
kernel-checked numerical refutations demonstrate the consequences of omitting
that distinction. Positive-zero accumulation of `(-0)*1` gives word0; the bare
product has word0x80000000. Reversing the finite list `[2^24,1,-2^24]` changes its
positive-zero-initialized result from0 to1. These concern the declared value
contract, with no source/backend correspondence claim.

All12 binary32 rank-zero profiles match an independent exact-rational rounding
oracle in convolution, Dot and reference form. They cover signed zeros and empty
initializers, subnormals, the normal boundary, ties, finite extremes and mixed
products. The oracle uses no host floating-point arithmetic and does not claim a
NaN propagation policy. The universal stored-value theorem includes exceptional
encodings through its operation-preserving proof. A heterogeneous Nat/Int,
non-associative fold with nonidentity finish returns94 in both forms.

All23 mathematical accounting tests pass. New tests distinguish signed zeros,
check normal/subnormal/tie boundaries, reject changed numerical observations and
prevent promotion to FMA/flags/cast-placement/backend/full-workload claims.
Fifteen new audited statements add241 custom Lean lines: S30/H105/R105/A1.
Total custom Lean is4165: S1131/H1497/R1124/A76/C337. The theory target has89
registered statements; the broader ledger audits319 distinct declarations.
Imported libraries, Python tools, semantic fixtures and audits remain separate.

All488 retained benchmark records remain:405 need formulation/domain partitions,
71 have partial evidence and12 carry the declared logical-value family. Whole
records closed stays0 and the logical family remains20 declared profiles.
The new two numerical refutations are recorded separately from positive value
proofs and neither is silently promoted to a whole-record outcome.

The initial frozen checker had a Python regex-result shape error and failed
before mathematical-result acceptance. Its snapshot and failure classification
are retained in `snapshots/convolution-ordered-v1.zip` and
`reports/convolution-ordered-v1-failed.json`. The corrected v2 changes no Lean
statement or measurement. This is an evidence-checker infrastructure correction,
not a mathematical proof-search failure.

Accepted pins: `census/convolution-ordered-v2.json`. Exact results:
`reports/convolution-ordered.json` and `reports/theory-progress.json`. Statement
and reproduction guide: `docs/convolution-ordered.md`.

Next establish the remaining numerical observation/precision partitions and
padding/layout/composition meanings, obtain independent review, and continue the
full-workload campaign and residual diagnosis. No final workflow verdict is
established. Code correspondence remains user-deferred future work.
