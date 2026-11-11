import TensorRewriteTheory

open TensorRewrite.Pilot
open TensorRewrite.Theory
open FloatLib.Floats

private def plan (channels : Nat) : Convolution.Plan 0 := {
  batchGroups := 1
  featureGroups := 1
  batchesPerGroup := 1
  inputFeaturesPerGroup := channels
  outputFeaturesPerGroup := 1
  window := Fin.elim0
}

private theorem pointwise (channels : Nat) : ConvolutionPointwise.IsPointwise (plan channels) :=
  fun axis => Fin.elim0 axis

private def output (channels : Nat) : Convolution.OutputIndex (plan channels) := {
  batch := ⟨0, by change 0 < 1; decide⟩
  batchGroup := ⟨0, by change 0 < 1; decide⟩
  featureGroup := ⟨0, by change 0 < 1; decide⟩
  feature := ⟨0, by change 0 < 1; decide⟩
  spatial := fun axis => Fin.elim0 axis
}

private def bits (word : Nat) : Binary32 := ExecFloat.Binary.ofNatBits word
private def word (value : Binary32) : Nat := ExecFloat.Binary.toNatBits value

private def evaluate (initial : Nat) (values weights : List Nat) : Nat × Nat × Nat :=
  let channels := values.length
  let p := plan channels
  let input : Convolution.Input p Binary32 := fun _ channel _ => bits (values[channel.val]!)
  let kernel : Convolution.Kernel p Binary32 := fun _ _ _ channel _ => bits (weights[channel.val]!)
  let actual := ConvolutionOrdered.convolve p ExecFloat.add (bits initial) (bits 0x7fc00000)
    ExecFloat.mul id input kernel (output channels)
  let reference := ConvolutionOrdered.convolve p ExecFloat.Spec.add (bits initial) (bits 0x7fc00000)
    ExecFloat.Spec.mul id input kernel (output channels)
  let dot := Contraction.dotTensor (ConvolutionDot.matrixPlan p) ExecFloat.add (bits initial)
    ExecFloat.mul id (ConvolutionDot.lhsMatrix p input
      ⟨0, by change 0 < 1; decide⟩ ⟨0, by change 0 < 1; decide⟩)
    (ConvolutionDot.rhsMatrix p (fun axis => ((pointwise channels) axis).unitKernel)
      kernel ⟨0, by change 0 < 1; decide⟩ ⟨0, by change 0 < 1; decide⟩)
    (ConvolutionDot.dotOutput p (ConvolutionPointwise.output_shape_eq p (pointwise channels))
      (output channels))
  (word actual, word dot, word reference)

private def heterogeneous : Int × Int :=
  let p := plan 3
  let input : Convolution.Input p Nat := fun _ channel _ => channel.val + 2
  let kernel : Convolution.Kernel p Int := fun _ _ _ channel _ => channel.val + 1
  let add := fun (acc value : Int) => 10*acc+value
  let multiply := fun (left : Nat) (right : Int) => (left : Int)*right
  let finish := fun value : Int => value % 97
  let original := ConvolutionOrdered.convolve p add 7 (-999) multiply finish input kernel (output 3)
  let target := Contraction.dotTensor (ConvolutionDot.matrixPlan p) add 7 multiply finish
    (ConvolutionDot.lhsMatrix p input ⟨0, by change 0 < 1; decide⟩ ⟨0, by change 0 < 1; decide⟩)
    (ConvolutionDot.rhsMatrix p (fun axis => ((pointwise 3) axis).unitKernel)
      kernel ⟨0, by change 0 < 1; decide⟩ ⟨0, by change 0 < 1; decide⟩)
    (ConvolutionDot.dotOutput p (ConvolutionPointwise.output_shape_eq p (pointwise 3)) (output 3))
  (original, target)

#eval do
  let profiles : List (String × Nat × List Nat × List Nat) :=
    [("finite_order", 0, [0x4b800000, 0x3f800000, 0xcb800000], List.replicate 3 0x3f800000),
     ("finite_reverse", 0, [0xcb800000, 0x3f800000, 0x4b800000], List.replicate 3 0x3f800000),
     ("negative_zero", 0, [0x80000000], [0x3f800000]),
     ("negative_initial", 0x80000000, [0x80000000], [0x3f800000]),
     ("empty_negative_initial", 0x80000000, [], []),
     ("subnormals", 0, [1, 2], List.replicate 2 0x3f800000),
     ("normal_boundary", 0, [0x007fffff, 1], List.replicate 2 0x3f800000),
     ("zero_negative_product", 0, [0], [0xbf800000]),
     ("half_ulp", 0, [0x3f800000, 0x33800000], List.replicate 2 0x3f800000),
     ("two_half_ulps", 0, [0x3f800000, 0x33800000, 0x33800000], List.replicate 3 0x3f800000),
     ("max_finite", 0, [0x7f7fffff], [0x3f800000]),
     ("mixed_products", 0, [0x3f000000, 0xbf000000, 0x3f800000],
       [0x40000000, 0x40000000, 0x3f800000])]
  for (name, initial, values, weights) in profiles do
    let (conv, dot, reference) := evaluate initial values weights
    IO.println s!"ORDERED case={name} conv={conv} dot={dot} reference={reference}"
  let (conv, dot) := heterogeneous
  IO.println s!"HETEROGENEOUS conv={conv} dot={dot}"
  IO.println s!"ORDERED_WITNESS name=product bits={word (ExecFloat.mul (bits 0x80000000)
    (bits 0x3f800000))}"
