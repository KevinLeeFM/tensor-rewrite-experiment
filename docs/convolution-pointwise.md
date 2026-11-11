# Exact pointwise convolution to a channel reduction

**Subsequent result:** the [matrix Dot bridge](convolution-dot.md) is now proved,
including flattening and both coordinate round trips. The original frozen
pointwise manifest/report records the preceding channel-sum checkpoint.

The mathematical convolution model now has a checked pointwise reduction. This
extends the frozen factored convolution model; it does not complete the whole
convolution benchmark family. Code correspondence remains future work.

## Statement

On every spatial axis, assume kernel extent one, stride one, base dilation one,
and zero low/high padding. Kernel reversal and positive kernel dilation remain
arbitrary. Output extent then equals input extent, including extent zero.

For any output batch group `g`, batch `b`, feature group `h`, output feature `o`
and spatial coordinate `x`, the theorem establishes

```
convolve(X, W)[g,b,h,o,x] =
  sum c : Fin C, X[g*B+b, h*C+c, x] * W[g,h,o,c,unitKernelIndex]
```

This is the separately defined `channelSum`: it has no spatial kernel loop,
optional input sampling, padding branch or window arithmetic. Coordinates retain
bounded types; `x` is transported along a proved shape equality. With `C = 1`,
`convolve_single_channel` eliminates the remaining sum and yields one product.

`IsPointwiseAxis` records the five window premises. `output_extent_eq` and
`output_shape_eq` derive the shape equality. `elementCount_unit` proves the
kernel has exactly one spatial coordinate at any rank. `base_position_eq`,
`axis_inputIndex_eq` and `spatial_input_eq` derive actual bounded sampling.
`sum_kernel_positions` reindexes the original `Fin (C * kernelCount)` loop to
`Fin C` using an equivalence. The main theorem is `convolve_eq_channelSum`.

All ranks, extents, batch/feature groups, batch sizes and channel counts are
parameters. Rank zero is included; an empty spatial extent gives no output
coordinate. Zero input channels with nonempty output give an empty sum, zero.
The algebra contract is Semiring with same-type input, product, accumulator and
output. Multiplication need not commute. No IEEE accumulation, conversion,
physical layout or source contract is established.

## Evidence and reproduction

The versioned manifest is `census/convolution-pointwise-v1.json`. It pins the
extension definitions/proofs, control fixture, checker and oracle, and identifies
the frozen base model. The mathematical ledger validates both base and extension
pins and their audited certificates. Run from this independent repository:

```sh
python3 tools/check_theory.py
python3 tools/check_convolution_model.py
python3 tools/check_convolution_pointwise.py
python3 tools/check_logical_family.py
python3 tools/mathematical_ledger.py
python3 -m unittest discover -s tests -p 'test_convolution*.py' -v
python3 -m unittest discover -s tests -p test_logical_family.py -v
python3 -m unittest discover -s tests -p test_mathematical_ledger.py -v
```

The pointwise checker compares both formulations to an independent general
integer-convolution oracle: 78 output coordinates in eight profiles. These
include a grouped two-dimensional example with multiple batches/channels/output
features; reversed and dilated unit kernels; zero channels; empty spatial domains;
rank zero; and absent batch groups. Empty profiles are recorded explicitly.
For rank zero with input channels `[1, 11]` and kernel channels `[3, 4]`, both
formulations return `47`. The one-channel condition is essential to the product
corollary; this two-channel value is not its first product, `3`.

Finite controls help inspect the model meaning; the arbitrary-size statement
is established by the Lean proof. Transitive axioms use only standard Lean
axioms. Independent statement/semantic review remains pending.

## Remaining mathematical work

A channel-only sum is the mathematical core needed for pointwise convolution
rewrites. The subsequent [Dot bridge](convolution-dot.md) proves the connection to the
existing `Contraction.dotTensor` model, including coordinate regrouping/flattening. The multiply/reduce benchmark
also permits other geometry and conversion partitions, which are not closed here.
No full benchmark record is promoted; mathematical N/F remains unfrozen. Numerical,
layout and effect theory, the diverse reviewed pilot, whole-workload campaign,
residual diagnosis and final independent replay are still required for a verdict.
