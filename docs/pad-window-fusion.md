# Ordered Pad/window fusion with derived geometry

Independent nonnegative Pad followed by an arbitrary ordered window is now proved
identical to a derived window on the original input. Every contribution stays in
its original position, including padding and dilation holes. The reducer, value
type and actual initializer are unrestricted. Explicit Pad fill and implicit
window padding must be the same value.

## Operators and geometry

`PaddingAxis` describes input extent n, nonnegative low/high padding L/H and
positive occupied spacing d (interior padding is d-1). Its padded extent is
N=L+span(n,d)+H, where span(0,d)=0 and span(n,d)=(n-1)*d+1 otherwise.
`pad` is independently defined by bounded lattice decoding, with multidimensional
failure on any absent coordinate. It is not defined by the window transformation.

The window template supplies positive stride s, base dilation b, kernel dilation,
signed low/high padding l/h and reversal. `outerAxis` replaces the template's input
extent with N. `fusedAxis` uses the original n and derives:

- Base dilation: d*b.
- Low padding: l+L*b.
- High padding: h+span(N,b)-L*b-span(n,d*b).

Stride, kernel extent, kernel dilation and reversal stay unchanged. The output
shape equality follows from these attributes; it is not a premise. The formula
supports simultaneous interior Pad and window base dilation as mathematical
geometry, without asserting that an external rewrite admits that combination.

For nonempty original input the high padding simplifies to h+H*b. When n=0 and
N>0 it is h+H*b-(b-1). When N=0 it is h. This empty-input distinction is necessary:
padding an empty input by one position on each side, then applying a unit kernel
with base dilation2, gives three outputs. The uncorrected h+H*b formula gives four.
`empty_high_formula_refuted` checks all three extents in Lean.

## Ordered equivalence and conversion

`LatticeIndex.decode_eq_some_iff` characterizes successful bounded decoding by
an exact occupied-point equation. `assemble_bind` proves composition of complete
optional coordinate maps, including rank zero and empty domains. `axis_compose`
and `sample_compose` connect actual independent Pad/window sampling to the fused
sampler. `values_fusion` proves equality of the complete ordered lists, and
`reduce_fusion` folds them with the same operation and initializer.

No neutral fill or initializer is required, because padding positions are retained.
Equal fill values are required: `unequal_fill_refuted` gives a contribution of5
from explicit Pad and2 from a proposed fusion using only the implicit fill2.
The refutation concerns this proposed mathematical statement, not compiler code.

`map_pad` moves any pure conversion through Pad with its actual converted fill.
`convert_reduce_fusion` proves the resulting converted graph equality for arbitrary
source/result scalar types. `convert_initial_fusion` substitutes the initializer
only under the explicit equation `convert fill = initial`. There is no scalar
homomorphism assumption and no conversion moved through the reducer. Stateful
conversions, exception flags and changed execution schedules remain separate.

## Validation and code burden

The23 statements comprise14 shared lattice/geometry results, seven graph/convert
results and two contract-refutation certificates. New custom Lean is387 lines:
S58/H212/R78/A1/C38. Total5963 (S1390/H2287/R1707/A82/C497),230 theory statements
and490 mathematical ledger declarations; four integration theorems are separate.
Mathlib supplies arithmetic/tactic infrastructure and the existing tensor/window
models are reused. Imported dependency code is not counted again.

The standalone IO fixture is outside primary proof-size accounting because it
uses interpolation. Its exact source is pinned and physical length reported in
the milestone JSON. An independent oracle materializes the Pad tensor, dilates
its occupied coordinate table and enumerates fitting outer windows. It does not
use the fused geometry or Lean's Pad decoder. All655 profiles/3043 output traces,
nonassociative integer folds and heterogeneous Int-to-Bool converted folds agree.
Profiles include empty/scalar/rank-two tensors, all small Pad edge/spacing choices,
cropping, striding, both dilations, reversal and empty kernels. Mutation checks
reject padding omission, wrong converted fill and unsupported coverage promotions.
All54 focused tests pass; see `reports/pad-window-validation-v1/`.

Sources and dependencies are pinned by `census/pad-window-v1.json`; results are in
`reports/pad-window.json`. The successor domain worksheet
`census/reduction-window-domains-v2.json` preserves all31 window records and the
immutable v1. It integrates the earlier Slice/Pad and full-span results with this
fusion:22 records now have partial core associations; nine still lack those
associations (four broadcast alternatives, four cumulative-count records, one
singleton-tuple record). These are retained candidate bindings, not a frozen N/F.

## Remaining scope

The two Pad-fold labels receive partial evidence; broadcast-sequence alternatives
are not proved. All488 records remain368 awaiting formulation/domain partitions,
108 partial and12 with the earlier declared logical-value family. Zero whole
records close. Negative explicit Pad attributes, representation/tuple partitions,
converted-fill matching, numerical observations and independent review remain open.
The141 theory statements added after the original reviewed89 are unreviewed;
the unchanged41-statement extension packet covers only part of that backlog.
The full mathematical campaign and final verdict remain open. Code correspondence
stays user-deferred future work.
