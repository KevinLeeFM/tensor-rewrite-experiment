# Independent review of HandlePad/compatible on rank-one descriptors

**Accepted for the frozen rank-one, zero-edge descriptor model.** The universal
runtime-length statement is classified exactly and the unbounded positive-gap
case has a kernel-checked counterexample. The counterexample concerns the modeled
local forwarding guard. Admission to an actual XLA pass pipeline remains open.
This is additional evidence for retained record `HandlePad/compatible`
(`site-L06248-C009`), with whole-record scope still unresolved. The reviewed
static tensor equality retains its original scope and verdict.

I reviewed candidate `e00b0dfad4890d8d0aad70d4fad47de79617f7e5` independently
of its author, against freeze `d9113ad`. The candidate changes none of this
packet's frozen contract, Lean specification or SHA-256 list. All nine input
hashes matched both the working files and exact candidate Git blobs. The proof
file SHA-256 is
`39308e05799689bdc7f10642b7935f944295f625f44c5343695f75879c52fda2`.

## Statement and source boundary

`RevisedBenchmark.DynamicPad.classify` proves, for each descriptor `d` and
interior gap `g : Nat`, that every admitted realization of `d` preserves its
length under Pad whenever `candidate d g` holds iff `d` is fixed/bounded or
`g = 0`. Fixed extents admit their exact size, bounded extents admit lengths
through their upper bound, and the unbounded model admits every natural length.
The raw guard excludes stored zero and stored one with positive gap, then
requires equal stored input and inferred output extents. No shape-preservation
assumption appears for concrete unbounded runtimes.

At XLA pin `e58e523b11f1fde802a493a776d158007486e1bf`,
[HandlePad 6198–6250](../../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L6198)
first tests the operand's stored zero dimension
([IsZeroElementArray](../../../../sources/xla/xla/shape_util.cc#L804))
and returns a fill broadcast when it finds one. It next clears positive interior
only on stored singleton axes and returns when it has made such a change.
The later `all_zero` condition tests low and high edges only. The unbounded
sentinel is INT64_MIN, so it triggers neither early return. The retained
[`HasInteriorPadding` declaration](../../../../sources/xla/xla/util.h#L503)
documents the nonzero-interior precheck. Its out-of-line body was unavailable
in this snapshot. [Shape sentinel and flags](../../../../sources/xla/xla/shape.h#L185)

[`InferPadShape`](../../../../sources/xla/xla/service/shape_inference.cc#L742)
checks rank, scalar/static fill, compatible operand types and nonnegative
interior. Its loop computes the finite product term with an overflow check
on fixed sizes or bounded upper bounds. For a stored unbounded axis it sets the
output dimension to the same sentinel and propagates the dynamic flag, bypassing
the finite calculation. Concrete model semantics put padding between actual
elements. These arithmetic functions use mathematical naturals and integers.
Machine overflow/status and graph construction are outside the theorem.
[Pinned Pad semantics](../../../../sources/xla/docs/operation_semantics.md#L3633)

The replacement helper also rejects control predecessors and requests
preservation of sharding and frontend attributes. `SameShape` uses
`ShapeUtil::Equal` in layout-sensitive mode and `Compatible` otherwise. The
latter ignores dynamic flags and layout, while the inferred descriptor here
copies the original dynamic flag. Layout and replacement/effect checks are
external compatible assumptions for the witness. The descriptor equality alone
cannot show that a graph replacement occurs.
[Replacement helper](../../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L861),
[SameShape](../../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L623),
[ShapeUtil comparisons](../../../../sources/xla/xla/shape_util.cc#L959)

The source verifier dispatches Pad to inferred-shape checking, but
`ShapeVerifier::Preprocess` rejects an unbounded instruction output when the
supported-unbounded predicate is absent or false. An appropriate pipeline
would need to allow both the unbounded operand producer and Pad among the
relevant instructions. The retained source search found the predicate setter
and verifier check, and no call site configuring the predicate for this
example. No native HLO run, backend behavior, C++–Lean correspondence, or
implementation bug is established.
[Verifier preprocessing](../../../../sources/xla/xla/service/hlo_verifier.cc#L117),
[Verifier Pad](../../../../sources/xla/xla/service/hlo_verifier.cc#L2121),
[Verifier option](../../../../sources/xla/xla/service/hlo_verifier.h#L102)

## Proof and discriminating controls

For a finite upper bound, equal inferred and stored extents force
`max(0, upper − 1) * gap = 0`. An admitted realization also has zero added
length, by the resulting zero gap or its length at most one. The fixed case can
directly substitute its unique realization. More specifically, a positive gap
can never reach this rank-one finite model guard. Stored zero is excluded by
the first return, stored one by the singleton return, and larger stored
extents by the dimension mismatch. These instances are vacuous implications.
Finite descriptors with stored size two and zero gap do fire the guard. In the
unbounded case the guard fires for every gap. The admitted length two forces
the gap to be zero if the length law is to hold uniformly. A zero gap gives
length equality directly for all realizations. The classification concerns
length, with general positive value preservation outside that theorem.

The packet certificate verifies that unbounded/one gap admits length two and
produces length three, and checks a differing value at shared index one
(Pad fill 99, forwarded value 8). The independent harness type-checked both
theorems at their explicit types, refuted the universal length law for
unbounded/one gap by applying the witness, checked unchanged realized lengths
zero and one, checked rejection of fixed-zero, bounded-one, fixed-two and
bounded-two descriptors with positive gap, and checked firing of fixed-two,
bounded-two and unbounded with zero gap. It also confirmed that bounded-two
admits actual length zero. To check the full readout independently, it built
`Tensor (fun _ : Fin 1 => 2) Nat` with values `[4,5]` and historical
`Params` deriving output extent three from zero edges and interior one.
Enumerating `List.finRange 3` via historical `SignedPad.tensor` with fill 99
gave `[4,99,5]`. Enumerating the forwarded input gave `[4,5]`. Those finite
checks use kernel-checked `by decide` or simplification, with no native
evaluation. `SignedPad.tensor` computes an occupied lattice sample when it
exists and otherwise returns the supplied fill. The equality comparison at the
shared index is between actual model tensor reads.

## Replay and accounting

From the repository root, the review used `sha256sum -c <packet>/SHA256SUMS`
and checked its entries again with `git show e00b0df:<path>`. In a fresh temp
directory created with `mktemp -d`, the packet's pinned
`signed-pad/extract.py <temp>` generated the historical modules from
`672928dbb90a7607c24a7d0281a7db117036608c`; all three generated files matched
`signed-pad/FREEZE.sha256`. The generated definitions are copied verbatim
apart from import/module scaffolding, with a few proof-only simp spelling
ports in the extractor. I inspected the import edges and the definitions
of extent, sample, selection and tensor. The shape theorem does not invoke
the imported singleton-spacing theorem. I copied the three new modules from
`git show e00b0df:<path>`. With the temp cwd and `LEAN_PATH` set to that
directory, each invocation used
`/workspace/toolchains/lean-4.35.0-linux/bin/lean -o <module>.olean <module>.lean`
and a 30-second process timeout. Lean reported version 4.35.0, commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Its shipped standard library
artifacts were reused. No Mathlib, Lake build, or historical theory replay was
needed for this closure.

| Module, in invocation order | Compiler s | Exit |
| --- | ---: | ---: |
| TensorRewrite/Pilot/Tensor | 0.365 | 0 |
| SignedPadLattice | 0.367 | 0 |
| SignedPadHistorical | 0.365 | 0 |
| DynamicSpec | 0.315 | 0 |
| DynamicPadSpec | 0.315 | 0 |
| DynamicPadProof | 0.369 | 0 |
| Independent ReviewerControls | 0.365 | 0 |

Total command durations were 2.461 seconds, including the independent controls,
with no Lean warnings. The theorem-level transitive axioms were
`propext, Classical.choice, Quot.sound` for `classify` and `propext` for
`witness`. Only permitted axioms occur. No `sorry`, `admit`, new axioms, or
`native_decide` occur in the fresh custom closure. This was independent
re-elaboration and kernel checking of source, with the standard library pinned.
The first replay wrapper failed before any Lean command because
`/usr/bin/time` was absent (exit 127). The rerun measured command durations
with Python's monotonic clock. Active reasoning, author proof search, and token
costs were not measured.

Observed review window: 22:26:09 to 22:28:42 UTC, including setup, source review,
replay, and report. Compiler durations fall within that window.
