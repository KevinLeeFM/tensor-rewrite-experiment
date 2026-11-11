# Pointwise convolution's exact matrix Dot identity

The former channel-only sum is now connected to the existing mathematical
`Contraction.dotTensor` model. Each batch-group/feature-group pair yields an input
matrix `[B*S,C]`, kernel matrix `[O,C]` and result `[B*S,O]`; `S` is the spatial
element count. The proofs establish both value directions and both coordinate
round trips. Thus matrix result coordinates are accounted for as well as the
image of convolution coordinates.

The explicit pointwise window assumptions are unchanged: unit spatial kernel,
unit stride/base dilation and zero low/high padding. Positive kernel dilation and
reversal remain arbitrary. Ranks, extents, batch/feature groups, batch sizes and
input/output feature counts are parameters, including zero counts and rank zero.
The exact Semiring contract uses same-type products, accumulation and results,
with identity finish and no requirement that multiplication commute. IEEE,
precision conversion and physical layout remain outside this result.

Twelve new statements pass kernel checking and transitive-axiom audit. The proof
uses the prior channel reduction, existing linear-index/finite-product inverses,
Mathlib finite sums, and the actual Dot ordered-fold definition. Two of the new
certificates prove coordinate inverses, independent of the value equality.

Eleven semantic profiles evaluate both operators with two independent enumeration
orders: convolution outputs and direct matrix rows/columns. All220 value/index
comparisons agree with a general independent integer-convolution oracle. The
unequal-spatial-extent grouped case `[2,3]` covers96 outputs per direction.
Other profiles cover one/multiple/zero channels, rank zero, kernel reversal and
dilation7, empty spatial domains, zero batches and absent groups/output features.
The checker requires empty profile counts, actual matrix row and output-feature
observations, source pins for both predecessor models and all12 audited names.

All17 mathematical accounting tests pass, including new controls rejecting lost
coordinates/directions, changed predecessor/extension sources and unsupported
IEEE/layout/full-family promotions. The earlier frozen base and channel-sum
artifacts remain unchanged. In particular the older channel-sum report's
`dot_tensor_bridge_proved=false` describes that historical checkpoint; the new
Dot report records the subsequent proof.

This milestone adds205 custom Lean lines: S50/H95/R59/A1. Total custom Lean is3698:
S1050/H1254/R983/A74/C337. Imported dependencies, Python tools, Lean semantic
fixtures and audit declarations remain separate. The theory target has63 checked
statements. The mathematical ledger now audits293 distinct declarations and
retains all488 benchmark records:407 need formulation/domain partitions,69 carry
partial model evidence and12 carry the declared logical-value family. Whole
benchmark records closed remains0; the complete logical family remains20 profiles.

The declaration/source pins are in `census/convolution-dot-v1.json`, exact control
and axiom evidence in `reports/convolution-dot.json` and
`reports/theory-progress.json`, and the complete registered audit in
`reports/mathematical-ledger-audit.{lean,log}`. The equation, coordinate meaning,
assumptions and reproduction commands are in `docs/convolution-dot.md`.

The exact mathematical pointwise matrix identity is proved. Independent semantic
review, remaining convolution geometry/conversion/numerical partitions, the global
mathematical workload, diverse reviewed pilot, all-case campaign and residual
interventions still prevent a final feasibility verdict. Code correspondence
remains user-deferred future work.
