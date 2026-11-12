# TensorRight's kernel-padding convolution case has no valid inputs

The paper artifact's `conv/rule01` fixes the input dilation and the original
kernel dilation to zero using `newConstMap`. In the executed tensor semantics,
convolution passes each dilation `d` to Pad as interior padding `d − 1`.
Pad requires interior padding to be nonnegative. Thus a spatial axis with the
rule's dilation zero would require `−1 ≥ 0`, which is false. The paper's
aggregated spatial axes are nonempty; the artifact's inferred rank is one for
this case. `ConvolutionVacuity.lean` checks the necessary arithmetic condition
for any nonempty spatial-axis group. This applies independently of tensor
values and element type.

The original TensorRight run and our full rerun both report success for this
case. A separate run of the unmodified, frozen convolution suite prints
`Pre-condition rules out all valid inputs (Or the rule is symbolically invalid)`
for both Int and Real, followed by success. The source-level dilation and Pad
conditions above explain which of the diagnostic's alternatives applies.
The complete output is in `convolution-vacuity.stdout` and
`convolution-vacuity.stderr`; `rerun_convolution_vacuity.sh` reproduces it.

The reported success is therefore vacuous under the artifact's executed model:
it does not establish the intended kernel-padding rewrite for any valid input.
This finding concerns the paper artifact's model and verifier result. It does
not establish any fact about the corresponding XLA implementation.
