# Factored exact convolution model

The current mathematical definition is
`TensorRewrite/Theory/Convolution.lean`, with geometry/boundary lemmas in
`ConvolutionLemmas.lean` and exact algebra in `ConvolutionAlgebra.lean`.
The versioned contract is `census/convolution-model-v2.json`.

## Contract

A Plan has arbitrary spatial rank and explicit batch groups, feature groups,
batches per group, input channels per group and output channels per group.
Inputs use bounded flattened group/batch and group/channel indices. Kernels and
outputs retain the group axes explicitly. This is a factored mathematical normal
form; no physical layout or implementation-dimension normalization is certified.

Each spatial axis has natural input/kernel extents, positive stride, positive base
and kernel dilation, signed low/high padding and an optional reversed kernel.
Dilated extent is0 for an empty dimension and otherwise `(extent-1)*dilation+1`.
Output extent is the nonnegative natural part of
`(paddingLow + dilatedInput + paddingHigh - dilatedKernel)/stride + 1`, using
mathematical integer division. The input sampler subtracts low padding, accounts
for stride/kernel dilation/reversal, checks base-dilation divisibility and returns
a bounded input coordinate. An invalid sample contributes zero. High padding
controls output extent. No unchecked coordinate access is used.

Scalar values form a Semiring. Input, product, accumulation and output values have
the same type; the model performs no precision conversion. Terms are indexed by
channel and spatial kernel position and summed exactly. Rounded IEEE arithmetic,
exception flags, backend behavior and effects are outside this model. Those
remain mathematical residuals or deferred implementation work as appropriate.
Independent semantic statement review remains pending.

## Proved properties

Twenty registered theorems cover sampler geometry, reversal, coordinate
reconstruction, zero-valued operands, empty input/kernel/channel fibers, linearity
in either operand, per-output-feature kernel scaling and biased-output scaling.
All ranks/extents/group counts remain parameters; the algebra requires no
commutative-multiplication law. The scaling factor is constant over the summed
channel/kernel coordinates but may vary with the output group and feature.

The model does not complete the convolution benchmark family. Pointwise
convolution-to-Dot/multiply, pad folding, arbitrary-axis/layout normalization,
precision promotion, float accumulation and other retained partitions still need
statements and proofs. Candidate benchmark labels in the ledger do not certify
correspondence to code.

## Verification

```sh
python3 tools/check_theory.py
python3 tools/check_convolution_model.py
python3 tools/mathematical_ledger.py
python3 -m unittest discover -s tests -p test_convolution_model.py -v
```

The checker audits the20 registered theorem dependencies, compares22 Lean
mathematical evaluations with an independent Python finite-sum oracle, and requires
rejection of zero stride and an application without a Semiring instance at
Binary32. The latter is a scope/type control; it is not a theorem that the finite
carrier can never carry some other algebraic structure. Four accounting tests
reject missing controls and promotion to IEEE or whole-family verification.

The v1 source snapshot is preserved in `snapshots/convolution-model-v1.zip` with
its manifest/result. V2 reflows overlong source lines to the adopted style; it
changes no mathematical statement. First accepted model code added272 Lean lines;
final formatted code adds281, for3318 custom lines in total. The snapshot is an
evidence/source archive, not a new independent clean replay of the full campaign.


## Pointwise extension

The frozen base model is extended by the separately versioned
[pointwise reduction](convolution-pointwise.md). It proves that unit spatial
kernels with unit stride/base dilation and zero padding reduce to a sum over
input channels, then to one product when there is one input channel per group.
The original base files and v1/v2 evidence remain unchanged.

The subsequent [Dot extension](convolution-dot.md) proves this pointwise
channel reduction equal to the existing matrix contraction model, with
bidirectional coordinate recovery and batch/spatial row flattening.
