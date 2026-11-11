# General exact convolution theory and semantic controls

This milestone introduces a factored mathematical convolution model and20
kernel-checked properties. It uses retained abstract benchmark labels and Lean
mathematical definitions. No C++ inspection, extraction, native pass execution or
code-correspondence task is performed.

## Generality and meaning

Spatial rank, extents, stride, both dilations, signed low/high padding, kernel
reversal, batch groups, feature groups and channel counts are parameters. Stride
and dilation must be positive; zero extents remain representable. Spatial output
sizes are derived from dilated extents and signed padding. Batch/channel packing
uses bounded Fin coordinates; invalid spatial samples contribute zero.

The model uses a Semiring, same-type products/accumulation/results and no finish
conversion. It includes exact integer/real-style algebra, not an adopted IEEE
convolution contract. Arbitrary physical layouts and kernel/input dimension
permutations are not modeled by the factored representation itself. Grouping is
explicit in the mathematical input/output coordinate types. The definition and
statement semantics still require independent review.

## Checked results

The20 declarations include:

- Negative sampled positions yield no input coordinate; kernel-reversal toggling
  agrees with reversing the bounded kernel coordinate; returned coordinates
  reconstruct exactly their base-dilation position.
- Zero-valued inputs or kernels yield zero; empty spatial input yields zero even
  when padding leaves a nonempty output; empty kernels or input-channel domains
  yield an empty sum.
- Convolution distributes over input and kernel addition.
- A right factor depending on output group/feature moves into the kernel.
- Scaling a biased output moves into both kernel and bias.

These equations quantify over all admitted plans and scalar values. Multiplication
need not commute. Proof reuse includes finite-list additive distribution and
right-factor extraction from Mathlib. The coordinate construction is derived from
the window parameters, not supplied as an assumed correct sampling function.

There are22 finite semantic vectors checked against an independent Python oracle:
plain/grouped/reversed convolution; positive padding and signed cropping; base
holes, kernel dilation and stride; empty input/kernel/channel domains; multiple
channels; invalid output coordinates; two spatial dimensions; varying output
features; bias scaling; and zero spatial rank. Examples include grouped output338,
reversed337, padded2, cropped8, and zero-spatial-axis channel contraction11.
The two biased-scaling forms both produce1029. Finite vectors check model meaning;
the unbounded equations are established by the Lean proofs rather than these runs.

Two negative compiler controls reject zero stride and using the exact-semiring
model at Binary32 without a Semiring instance. No floating algebra theorem is
inferred from that typeclass rejection. Four convolution-accounting tests reject
missing controls and illicit claims of IEEE precision/layout or whole-family
completion. The four logical-family and three mathematical-ledger tests also pass.
All accepted theorem dependencies are standard Lean axioms only.

## Inventory, size and remaining work

The theory target now has38 registered statements and the mathematical ledger
checks268 distinct registered declarations. All488 retained benchmark records
remain present:409 need statement/domain formulation,67 have partial model
evidence, and12 have the previously completed declared logical-value family.
Whole-record mathematical partitions and the full denominator remain open. The
new convolution theory is explicitly partial and does not increase the closed
logical-family profile count20 or close all31 convolution benchmark records.

The initial model added272 custom Lean lines. A formatting-only revision preserves
v1 bytes and measurements in `snapshots/convolution-model-v1.zip`, with the v1
manifest and result kept unchanged. Current v2 code adds281 lines:
S89/H108/R83/A1. Total custom Lean is3318, split S967/H1086/R856/A72/C337.
Tests/audits, the Python oracle/checker and imported libraries remain separate.

Evidence: `reports/convolution-model.json`, `reports/theory-progress.json`,
`census/convolution-model-v2.json`, the three convolution Lean modules and
`tests/fixtures/ConvolutionControls.lean`. Reproduction commands and precise scope
are in `docs/convolution-model.md`. Build, all model checks and11 mathematical
accounting tests pass. This is not the final independent full-campaign replay.

Next: formulate the remaining convolution partitions and mathematical workload,
extend numerical/precision, layout and effect theory, complete the diverse reviewed
pilot and all-case campaign, and diagnose residuals before a research verdict.
Code correspondence remains user-deferred future work.
