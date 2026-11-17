# Signed Pad terminal model observations

The two target record IDs are `HandlePad/unit-interior` and `HandlePad/empty-input`.
The whole-benchmark assignment and remaining records are governed by the
[parent contract](../CONTRACT.md). Baseline is
`672928dbb90a7607c24a7d0281a7db117036608c`. Source interpretation uses pinned
XLA `e58e523b11f1fde802a493a776d158007486e1bf`.
The compiler is Lean 4.35.0 (`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`)
with its shipped Std. The repository Mathlib and FloatLib manifest is retained
for provenance. Neither external dependency is imported by the extracted closure.

- `UnitInteriorGoal` models the nonempty-input path in [HandlePad lines 6198–6222](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L6198).
  At least one axis must have positive original interior and input extent one.
  This entails the intended `HasInteriorPadding` fast precheck and flag. The
  retained source contains the declaration of that utility, but its out-of-line
  definition is absent. A clear updates precisely the positive singleton
  interiors, preserving both signed edges and the output shape. The constructor
  derives the replacement's shape equation using historical `extent_unit`.
- `EmptyInputGoal` models the earlier dispatch when any finite input extent
  is zero, as tested by [IsZeroElementArray](../../../sources/xla/xla/shape_util.cc#L804).
  It compares the same tensor shape to scalar broadcast with no mapped axes.
  A valid signed Pad can have a nonempty output, with a returned value at every
  output index, even though there is no input coordinate. A rank-zero input
  does not meet the empty or clear guard.

Both observations cover arbitrary finite rank, data type and admitted static
logical values under the Pad model, including zero output extents where shape
equations permit them. [InferPadShape](../../../sources/xla/xla/service/shape_inference.cc#L742)
motivates the nonnegative shape equation. Source-to-model translation is assumed.
Dynamic dimensions and descriptors, fixed-width overflow, metadata, physical
layout, execution effects, verifier constraints beyond this model and C++–Lean
correspondence are outside the statements. There is no whole-record claim.

The generated closure `SignedPadLattice` and `SignedPadHistorical` keeps the
pinned historical definitions verbatim and reuses the proofs from the selected
source ranges. This closure drops unrelated Mathlib imports/theorems. Three
proof-only simp lists qualify or substitute Std lemmas in `extract.py`.
The original historical modules and replay remain separate and are unchanged.

Completion requires exact proofs of both frozen Props with only `propext`,
`Quot.sound` and `Classical.choice` permitted, no unchecked evidence
scaffolds, fresh targeted replay, signed multiaxis nonempty controls, a
wrong-interior discrimination control, and an empty-input control with nonempty
output. Both modeled partitions require a fresh independent reviewer before
ledger credit. Project-level scope remains open.

The coordinator owns the register and independent acceptance. The proof worker
owns only this packet. After the freeze, proof-worker changes are limited to
`SignedPadProof.lean`, `SignedPadControls.lean` and attempt evidence.
The five-minute supervisor check uses actual compiler results and status.
