# Kernel-checked empty-slice shape refutations

Source pin: e58e523b11f1fde802a493a776d158007486e1bf.
Lean pin: 4.35.0, Std only; no Mathlib or external proof-producing solver.

## Contract

TensorRewrite/Pilot/SliceShape.lean models one static slice axis as start,
exclusive limit and stride, retaining invalid combinations as representable
data. IsWellFormed checks nonnegative ordered bounds within the input extent,
a positive stride, a nonnegative declared output extent and agreement of that
extent with `(limit-start+stride-1)/stride`.

Arithmetic uses mathematical Int with explicit Int.tdiv, which truncates toward
zero. This is essential for the reverse helper's `(limit-start-1)/stride` on an
empty slice: -1 divided by 2 is zero under the source convention. Lean's ordinary
Int division gives -1 and would describe a different transformation. A control
checks both results. This model does not claim arbitrary signed-int64 arithmetic
is overflow-free or formalize C++ execution.

The source-shaped one-axis functions retain the source's redundant-stride guard
and its limit/start updates, and the reverse helper's step count and bound
updates. The preserved declared output extent is an argument to the legality
contract, not silently recomputed after mutation.

## Certificates

TensorRewrite/Pilot/EmptySliceRefutation.lean checks seven declarations:

- the original [1:1:2] witness is legal for input extent4 and declared extent0;
- exact bounds after redundant-stride removal are [1:2:1];
- those bounds are incompatible with the retained declared extent0;
- exact bounds after reverse reordering are [2:3:2];
- those bounds are also incompatible with retained declared extent0;
- each transformation therefore fails universal preservation of this static
  shape contract from legal inputs.

The last bullet is two theorems, giving seven total: four refutation theorems,
two exact-bound witness facts and one input-legality consistency theorem. These
are two source targets, not seven rewrites. All seven axiom reports are empty.
Proofs use kernel reduction/decide and direct application of the concrete
counterexamples; no native_decide, sorry or new axiom is used.

The input validity theorem prevents refuting an ill-formed source. Positive
controls include legal endpoint-empty and nonempty slices and successful
nonempty transformed bounds. Negative controls reject reversed bounds, stride0,
and a deliberately false proof claiming the transformed element count is zero.

## Source correspondence evidence and limits

The exact pinned XLA pass reproduces both shapes in
reports/empty-slice-replay-v2/result.json, with successful input verification,
expected failing output verification and a valid nonempty control. Pinned shape
inference, verifier and slice-constructor implementations are hashed in
sources/indexing-contract-manifest.json; source references and branch reasoning
are in reports/indexing-census.md.

This connects the certificates to actual observed source behavior through an
inspected translation and matching replay. It is not a machine-checked source
extractor, whole C++ graph theorem, independent correspondence review or a
universal overflow proof. The witness values are small and the real run observes
the same arithmetic; a formal signed-int64 range bridge is still recorded as
open. Static shape preservation is refuted without assumptions about numerical
rounding, NaNs or fast math.

## Code burden

reports/pilot-values.json counts the complete current development:
S148, H66, R172, A9, C106 = 501 custom Lean code lines. The new contribution is
S30 for the static-axis model, C33 for its certificates and A1 for the import;
tests/audit commands are measured separately. Positive correctness-rule R is
unchanged. There remain 41 positive value identities, nine support lemmas and
zero accepted full-source rewrites. Separately, there is one numerical and two
shape targets refuted under explicit contracts.

The first checked sources, ledger, checker and measured baseline are preserved
in snapshots/empty-slice-certificates-v1.zip, including the existing value pilot.
A replay from a fresh temporary directory without a project .lake cache passes
all proof/control checks and reproduces the exact code counts and axiom audit;
reports/empty-slice-certificate-clean-replay.json records that result. This is
clean replay by the same agent, not independent source/profile review.
Sizes are observed artifacts, not minimal proof lengths or model-independent
difficulty estimates. Shared definitions and integration code stay in the total.
Source inspection, non-Lean harness work and actual-XLA validation are additional
work outside this primary code-size measure and must remain visible in reports.
The complete census and final automatic-verification verdict remain open.
