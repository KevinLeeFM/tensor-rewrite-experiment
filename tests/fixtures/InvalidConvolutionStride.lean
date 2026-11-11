import TensorRewriteTheory

open TensorRewrite.Theory.Convolution

-- Zero stride cannot satisfy the geometry contract.
example : Axis :=
  { inputExtent := 1, kernelExtent := 1, stride := 0, baseDilation := 1,
    kernelDilation := 1, paddingLow := 0, paddingHigh := 0, reversed := false,
    stride_pos := by decide, baseDilation_pos := by decide, kernelDilation_pos := by decide }
