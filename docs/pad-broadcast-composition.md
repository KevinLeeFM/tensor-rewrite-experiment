# Raw Pad/window to Reshape/Broadcast composition

The two combined Pad/broadcast candidate branches now have a mathematical core
proof. Thirteen statements add242 custom Lean lines: S78/H82/R41/A1/C40. They
reuse the existing Pad fusion, covered singleton windows, bounded indices and
actual logical Reshape/Broadcast operators. No library or toolchain pin changes.

## Admission from independent attributes

`PadBroadcast.Expansion` stores the actual nonnegative Pad attributes and outer
window template. The original extent is one and outer kernel dilation is one.
Stride, base dilation, Pad interior spacing and reversal remain explicit and
positive where required; outer low/high padding is signed. Define the occupied
offset `L = outerLow + padLow*outerBase` and derive the actual outer output extent O.
Coverage is either O=0 or `0 ≤ L ∧ L < K ∧ (O-1)*stride ≤ L`, with kernel extent K.
These are conditions on raw attributes and actual outer bounds, not a premise
that two sample maps or output shapes already agree.

`KeptAxis` supports arbitrary original extents, including zero. It requires unit
Pad spacing and outer base/stride/kernel, with `outerLow=-padLow` and
`outerHigh=-padHigh`. Thus retained axes may have nonzero edge Pad that the outer
window crops away. Kernel dilation and reversal may vary on these unit kernels.
Interior holes cannot simply be discarded on retained nonunit axes.

The compiler builds a `BroadcastWindow.Plan`. `kept_pointwise` derives its retained
axis conditions, `expansion_axis` identifies the actual complete fused singleton
attributes, and `expansion_covers` derives terminal coverage using the independently
proved outer/fused extent equality. `fused_window` proves complete axis-attribute
equality at arbitrary finite ranks and for mixed axis choices. Output bounds and
input/target shapes are transported only through this derived equality.

## Graph and fill preservation

`reduce_sequence` starts with the independent Pad tensor followed by the actual
outer ordered window. It composes `PadWindow.reduce_fusion` with the terminal
Reshape/Broadcast theorem. Actual implicit padding and explicit Pad fill equal the
initializer, and the reducer has that initializer as both identities. Associativity
is unnecessary because each output has exactly one original live contribution.
Empty output, scalar tensors and retained empty axes are included.

`reduce_converted_sequence` covers any pure input conversion and an arbitrary
result reducer satisfying those identities. It requires the actual source Pad
fill to convert to the result initializer. Conversion can then occur after the
constructed Reshape/Broadcast sequence. It is never moved through an arbitrary
reducer without a homomorphism; here the proof uses the unique-live-contribution
geometry. Stateful conversion, exception flags and changed schedules are outside
the pure value contract.

For input `[5]`, Pad low/high1 and an unpadded full kernel3 give `[0,5,0]`. A
zero-unital reducer returns5, equal to reshape-to-scalar then Broadcast. Under
conversion `x+1`, source Pad fill0 converts to1. Multiplication with initializer1
folds `[1,6,1]` to6, exactly conversion after the target. No conversion homomorphism
is needed. Applying addition with initializer0 to the converted list instead gives8;
its actual converted fill1 is nonneutral. The checked certificates expose this
failure, direct explicit fill2 producing9 instead of5, and retained interior
spacing2 changing original extent2 to fused extent3 despite edge cancellation.
These are mathematical contract counterexamples, not compiler bug claims.

## Validation and remaining scope

Run `python3 tools/check_theory.py`, `python3 tools/check_pad_broadcast.py` and
`python3 tools/mathematical_ledger.py`. The full mathematical replay and70 focused
Python tests pass. Exact commands/logs are in `reports/pad-broadcast-validation-v1/`;
inputs are frozen in `census/pad-broadcast-v1.json`. The103 physical IO fixture lines
are separate from primary lexical proof-size accounting because of interpolation.

The independent oracle materializes every Pad tensor before sampling outer
windows. It enumerates fitting windows and tests coverage by counting hits at the
original occupied location, without using the fused low/high formulas or first/
last inequalities. It constructs a separate flatten/reshape/Broadcast target.
All14,400 raw axis configurations agree;3,776 are admitted. Nine additional mixed,
scalar and empty profiles give3,785 tensor profiles and1,805 outputs. Controls
compare complete ordered traces and values under a nonassociative zero-unital
integer reducer, plus converted traces folded by multiplication with initializer1.
They include nonzero edge Pad canceled on retained axes, reversal, base/interior
dilation, negative outer padding, empty kernels and empty outputs. Mutation tests
reject changed axis order, missing converted fill, omitted certificates, source/
dependency drift and unsupported promotion of these partial results.

Worksheet v5 preserves the same31 window records and the immutable v4. All31 now
have a core association; the two combined branches remain **partial mathematical
profiles**. This does not discharge every dtype/geometry/observation partition.
Nonnegative explicit Pad, unit singleton kernel dilation and the retained-axis
conditions delimit this proof. IEEE identity domains, representation, effects,
layout, independent statement review and full-workload formulation remain open.
No unrestricted floating-point addition identity is asserted.

Current totals:313 theory statements,573 ledger declarations and four separately
audited integration results;7,307 custom Lean lines (S1694/H2934/R2001/A86/C592).
Complete declared value profiles remain21. All488 retained records remain359
awaiting formulation/domain partitions,116 partial and13 carrying declared value
families. Whole-record closure stays zero; mathematical N/F and the final workflow
verdict remain unresolved. Of the313 theory statements,224 were added after the
original89-statement review and await independent review. Code correspondence is
user-deferred future work. Earlier packet flags describe their narrower historical
models and remain unchanged; this successor records the new composition proof.
