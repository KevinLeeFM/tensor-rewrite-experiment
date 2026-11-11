# Ordered reduction windows and an affine gather transformation

The window model reuses the bounded axis sampler already defined for convolution.
A plan supplies arbitrary finite rank, natural extents, positive stride and both
positive dilations, signed low/high padding and a kernel-reversal flag. The
trivial convolution group fields are unused by sampling. Every bounded kernel
coordinate contributes one value, in row-major kernel order: either a valid
input value or the supplied invalid-sample value. The fold initializer is a
separate parameter. No invalid position is silently skipped.

The model uses mathematical Nat/Int attributes. Degenerate empty windows are
representable without claiming that an external IR admits them. Machine-width
attribute decoding/overflow and external operator admission are not established.
Scalar values and pure whole-state tuple reducers remain arbitrary.

## Checked results

| Profile | Result and explicit premises |
| --- | --- |
| Empty kernel | No updates; return the actual initializer |
| Empty input | Fold one padding value per kernel position |
| Empty input, padding=initializer | Return initializer if op(initial,initial)=initial |
| Empty output | Equality is observationally vacuous; no reducer law needed |
| Unit window | Exactly op(initial, contribution), with no algebraic law |
| Unit window, undilated input | Independent affine crop/stride gather; target pad fill requires op(initial,padding)=padding |
| Exact neutral addition | Gather with zero fill under AddZeroClass |
| Exact min/max | LinearOrder; retain actual initializer and padding |
| Pointwise unpadded geometry | One initialized operation at the transported input coordinate |
| Pointwise elimination | Additionally require a whole-state initializer left identity |
| Entire input cropped | Derive invalid samples from outside-axis witnesses; a sufficient low-side crop condition is proved |
| Empty tuple-state input | Project actual initializer components after the coupled whole-state fold |

For a unit window, every kernel coordinate is zero, including under reversal or
kernel dilation. With base dilation one, the bounded sampler is proved equal to
an independently defined affine coordinate check:

`position(axis) = output(axis) * stride(axis) - paddingLow(axis)`.

Every coordinate must lie in the input extent. This derives the index relation
rather than assuming the desired tensor equality. Arbitrary positive stride and
signed padding remain quantified; empty/rank-zero shapes are included. The
all-cropped result additionally has a derived sufficient condition: one axis has
paddingLow <= -inputExtent. High-side and other crop conditions still need their
own general geometry derivations; the finite high-crop control is not that proof.

The affine gather is a fused mathematical target. Equality with the separately
constructed Slice-then-Pad graph in the retained records is not proved. That
factorization, full-span windows, Pad/Broadcast/Convert composition, cumulative
sample counts and their numerical/representation partitions remain work.

No IEEE addition instance satisfying AddZeroClass is supplied. In stored floating
values, omitting the initializer can change signed zero; generic unit-window
results retain its operation. Linear-order extrema do not establish floating
NaN/signed-zero semantics. General ordered results assume neither associativity
nor commutativity; they do not justify swapping operand or contribution order.

Two separately counted certificates expose omitted padding conditions. With
empty input, a unit padded output and addition with initializer=padding=1, the
window returns2 while padding the target with1 returns1. A three-sample window
with values[3,2,3] and initializer3 returns11; skipping invalid positions returns5.
These refute strengthened mathematical claims, not compiler implementations.
Only the standard allowed Lean axioms occur in the audit.

## Reproduction and measurement

```sh
python3 tools/check_theory.py
python3 tools/check_reduction_window.py
python3 tools/mathematical_ledger.py
python3 -m unittest discover -s tests -p test_reduction_window.py -v
```

The29 new statements comprise12 support lemmas,15 positive/domain results and2
counterexample certificates. New Lean is322 lines: S64/H85/R139/A1/C33. The total
is4920, with S1230/H1749/R1444/A79/C418. Imported library/model code already in the
baseline is reused rather than charged twice. The61 physical-line IO fixture is
separate; interpolation in that fixture is outside the primary lexical counter's
accepted language. Primary mathematical files satisfy the supported convention.

Fifteen profiles produce45 observations matching an independent occupied-coordinate
lookup/containment oracle. They include rank zero, positive/negative padding,
strides, base-dilation holes, dilated/reversed kernels, empty inputs/windows/outputs,
and multidimensional sampling. A decimal fold observes contribution order; minima,
maxima and separate initializer/padding values expose other distinctions. These
controls check selected meanings; Lean proofs supply the unbounded generality.

All42 focused mathematical accounting/integrity tests pass. Inputs/results are
pinned by `census/reduction-window-v1.json` and `reports/reduction-window.json`.
The domain map retains all31 window records, with partial core evidence for19;
no complete per-record graph/observation outcome follows. All488 records remain:
371 need formal statements/domain partitions,105 are partial and12 carry the
previous declared logical-value family; zero whole records closed. Current
theory/ledger totals are159/419, with four integration theorems separate.

The29 additions await independent review. They are outside the already frozen
41-statement extension packet, whose authorization remains pending; that packet
and the earlier89-statement review are unchanged. Mathematical N/F, the full
campaign and the final positive/negative workflow verdict remain open. Code
correspondence stays user-deferred future work.

## Later graph refinement

The initial milestone's separate graph gap above is now closed for its canonical
unit/undilated profile by [the constructed Slice/Pad extension](slice-pad-factorization.md).
That extension derives actual ordinary Slice attributes and output shape, retaining
the initializer/padding law. The original window model and its historical result
are unchanged. Other numerical/full-span/composition partitions remain open.


## Later full-span refinement

[The full-span extension](full-span-window.md) proves the canonical mixed
kept/full-span window equal to ordered reduction and the derived logical reshape.
It preserves arbitrary operations and initializers. The original window model
and frozen evidence above remain unchanged; compositions, numerical partitions
and full-family formulation/review remain open.


## Later Pad fusion and current domain worksheet

[The Pad/window extension](pad-window-fusion.md) defines independent nonnegative
edge/interior Pad and derives the composed window geometry, including empty input,
with identical complete ordered lists and pure converted-fill preservation.
The immutable v1 worksheet above is superseded for current mathematical tracking
by `census/reduction-window-domains-v2.json`: all31 records remain,22 with partial
core associations after Slice/Pad, full-span and Pad-fusion extensions. Broadcast,
cumulative/tuple and whole-record partitions remain open.


## Later cumulative-prefix refinement

[The prefix extension](prefix-window-counts.md) derives ordered prefixes, arbitrary
positive retained strides, exact/same-width modular inclusive-Iota products and
precise signed/unsigned count-observation domains. The current domain worksheet
is `census/reduction-window-domains-v3.json`: all31 records remain,26 with partial
core associations. Four broadcast alternatives, one singleton tuple and full
per-record partitions/observations remain open; earlier frozen worksheets remain.
