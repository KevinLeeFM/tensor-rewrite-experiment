# Exact pointwise convolution as matrix Dot

**Subsequent extension:** the [ordered scalar theorem](convolution-ordered.md)
proves equal contribution lists and folds without algebra assumptions, including
a pinned binary32 stored-value specialization under the same schedule.

The mathematical bridge from pointwise convolution to the existing Dot model is
proved in `TensorRewrite/Theory/ConvolutionDotProof.lean`. The matrix definitions
are in `ConvolutionDot.lean`; bounded coordinate recovery is proved in
`ConvolutionDotLemmas.lean`. This extends the earlier channel-sum checkpoint.

## Equation and coordinate meaning

Assume every spatial kernel extent is one, stride and base dilation are one,
and low/high padding are zero. Positive kernel dilation and reversal remain
arbitrary. Output spatial shape equals input spatial shape by a preceding proof.
Use exact Semiring values with same-type multiplication/accumulation/results
and identity output conversion. Multiplication need not commute.

Let `B` be batches per group, `S` the spatial element count, `C` input channels per
group, and `O` output features per group. For each batch-group/feature-group pair,
construct actual operands for the existing contraction model:

- `A : [B*S,C]` unflattens its row into batch and spatial input coordinates.
- `W : [O,C]` selects the output feature, input channel and unique kernel coordinate.
- `Dot(A,W) : [B*S,O]` contracts the operands' second axes, preserving `A * W` order.

The contraction plan has no paired batch axes, one left free row axis, one right
free output-feature axis and one contracted channel axis. Its operand axis
permutations are identities. This is the existing ordered `dotTensor` definition,
with addition, zero, multiplication and identity finish supplied explicitly.

`dotOutput` packs an output's batch and spatial coordinates into the matrix row;
the output feature becomes its column. `convolutionOutput` decodes a matrix result
within a fixed group pair. The row is `batch*S + linearize(spatial)`. The two maps
are inverse, with batch/feature groups fixed on the matrix side.

`convolve_eq_dot` proves the equality at every convolution output. Conversely,
`dot_eq_convolve` proves it at every matrix result in every existing group pair.
The proof derives Dot's channel sum from its actual ordered fold, using exact
additive laws, then reuses the preceding pointwise-convolution theorem.

Ranks, extents, group counts, batch sizes and feature counts are arbitrary.
Rank zero has one spatial coordinate. Zero spatial size or zero batches give no
matrix rows. Zero input channels give zero at each existing result. No positive
size premise is hidden in unflattening: each division consumes a bounded index,
whose existence rules out the relevant zero extent.

## Evidence

Twelve statements cover operand index selection, matrix output fields, both
coordinate round trips, channel-domain reindexing, Dot's channel sum and both
value directions. Their axiom dependencies are standard Lean axioms only.

The semantic controls evaluate the actual convolution and actual Dot. Eleven
profiles compare220 values and observed matrix row/feature coordinates against
an independent general integer-convolution oracle. One enumeration starts from
convolution coordinates; the other starts directly from matrix rows/columns.
The grouped example uses unequal spatial extents `[2,3]`, two batch groups, two
batches per group, two feature groups, three input channels and two output
features. Rank zero, zero input channels, reversed/dilated unit kernels, empty
spatial size, zero batches, and absent groups/output features are also retained.
Empty profile/direction counts are checked rather than omitted.

The extension's versioned manifest pins new sources and the frozen predecessor
model manifests. Its checker validates both predecessor source closures. Reports
retain exact outputs and the broader ledger retains all488 benchmark records.
This is a complete kernel proof of this declared exact mathematical identity;
independent statement/semantic review and full benchmark partitions remain open.
IEEE accumulation, precision conversions, physical layouts and C++ correspondence
are not established. No whole benchmark record or full convolution family is
newly closed; earlier pointwise reports remain historical checkpoint evidence.

## Reproduce

From the standalone repository:

```sh
python3 tools/check_theory.py
python3 tools/check_convolution_dot.py
python3 tools/mathematical_ledger.py
python3 -m unittest discover -s tests -p 'test_convolution*.py' -v
python3 -m unittest discover -s tests -p test_logical_family.py -v
python3 -m unittest discover -s tests -p test_mathematical_ledger.py -v
```

The statement manifest is `census/convolution-dot-v1.json`; exact controls and
certificate dependencies are in `reports/convolution-dot.json` and
`reports/theory-progress.json`. Imported libraries, test fixtures, audit files
and Python tooling are measured separately from the custom Lean proof subtotal.
