# Mixed-window convolution as products and reduction

`ConvolutionSeparable.convolve_eq_productReduction` proves a general exact
mathematical identity for convolution axes that are either pointwise or spanning.
Each spatial axis must have kernel extent one or output extent one. Stride,
base dilation and kernel dilation are one; padding is zero. There is one input
channel per feature group. Reversal is independent on each spatial axis.

## Meaning of the replacement

A unit-kernel axis preserves its input/output extent and reads the output
coordinate. A nonunit kernel with one output position spans the entire input
axis, including the empty extent case. Its input coordinate comes from a
reduction coordinate. These relations are derived from the window arithmetic;
the theorem does not assume an externally correct sampling function.

The replacement is a product with a broadcasted/reindexed kernel, followed by
a sum over **only nonunit kernel axes**. Unit spatial axes and the sole input
channel are removed from the reduction domain. Reversal is applied to the kernel
operand, while the input coordinates increase in the unreversed direction.
For each output `o`, it has the form

```
sum r : ReducedIndex plan,
  input[batch(o), featureGroup(o), productInputIndex(o, expand(r))] *
  kernel[groups(o), feature(o), channelZero, reverseKernel(expand(r))]
```

`ReducedAxis` is the subtype of spatial axes with kernel extent different from
one; `ReducedIndex` has bounded coordinates only on those axes. Expanding and
projecting these coordinates are proved inverse. Selected-axis reversal is
involutive. With one input channel, full kernel coordinates and the original
linear contribution positions are equivalent. Composing these maps proves that
all original contributions are covered, including the zero-size cases.

The value proof changes the actual finite sum domain using that equivalence.
It then proves each reindexed contribution samples the derived input coordinate
and reversed kernel. The target has no optional sampling, padded positions,
window arithmetic, channel loop or unit-axis reduction loop.

The algebra contract is same-type Semiring multiplication/addition with no finish
conversion. Multiplication need not commute. Finite-sum reindexing uses exact
commutative additive laws; it supplies no rounded floating-point theorem. Ranks,
spatial extents, groups, batches and output features are arbitrary. Empty kernels
can have nonempty output: their reduction domain is empty and returns zero.
Rank zero and an all-unit kernel have a one-element reduction domain.

## Retained domain worksheet

`census/convolution-mathematical-domains-v1.json` preserves all31 retained
convolution benchmark records. It distinguishes12 multiply/reduce variants,
including nine with input or kernel conversions, and seven helper-composition
references. It also records scalar movement, bias scaling, padding, promotion,
pointwise Dot and empty-convolution partitions. Retained guards remain provenance,
not adopted theorem assumptions. The worksheet is not an independently reviewed
list of final formal obligations and does not freeze mathematical N/F.

The new exact core provides partial model evidence for the no-conversion
pointwise/reduce labels. Conversion, rounding/accumulation observations, typed
broadcast/result adapters and independent review remain explicit gaps. Helper
references need mathematical replacement/composition definitions before they can
be normalized into the final denominator. No whole record is promoted.

## Check and reproduce

Eleven new audited statements cover output geometry, bounded sampling, coordinate
inverses, reversal, the composed-domain formula and the value theorem. All use
standard Lean axioms only. Eleven semantic profiles compare123 outputs with an
independent general integer-convolution oracle and observe reduced-axis counts
and reduction-domain sizes. The spanning example gives14 without reversal and10
with reversal. Mixed grouped 2D and three-axis cases, all-spanning/all-unit
kernels, rank zero, empty kernel/output and absent groups are included.

```sh
python3 tools/check_theory.py
python3 tools/check_convolution_separable.py
python3 tools/mathematical_ledger.py
python3 -m unittest discover -s tests -p 'test_convolution*.py' -v
python3 -m unittest discover -s tests -p test_logical_family.py -v
python3 -m unittest discover -s tests -p test_mathematical_ledger.py -v
```

The versioned source/worksheet pins are in `census/convolution-separable-v1.json`;
exact outputs and certificate axioms are in `reports/convolution-separable.json`.
Independent statement review, the remaining numerical/layout/padding/composition
partitions, the full campaign and a final feasibility verdict remain open.
Code correspondence is user-deferred future work.

The [ordered numerical extension](convolution-ordered.md) proves the pointwise
Dot case without algebra laws. Its kernel-checked signed-zero and reversal
examples also show why the mixed-window exact sum reindexing needs a separate
rounded accumulation/observation argument.
