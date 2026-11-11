import TensorRewriteTheory
import Mathlib.Tactic.NormNum

open TensorRewrite.Theory.Convolution

private def baseAxis : Axis :=
  { inputExtent := 5, kernelExtent := 2, stride := 1, baseDilation := 1,
    kernelDilation := 1, paddingLow := 0, paddingHigh := 0, reversed := false,
    stride_pos := by decide, baseDilation_pos := by decide, kernelDilation_pos := by decide }

private def plan1 (axis : Axis) (batchGroups featureGroups channels : Nat) : Plan 1 :=
  { batchGroups := batchGroups, featureGroups := featureGroups, batchesPerGroup := 1,
    inputFeaturesPerGroup := channels, outputFeaturesPerGroup := 1, window := fun _ => axis }

private def evaluate (axis : Axis) (batchGroups featureGroups channels : Nat)
    (batchGroup featureGroup position : Nat) (scale : Int := 1) (bias : Int := 0) : Option Int :=
  if valid : batchGroup < batchGroups ∧ featureGroup < featureGroups ∧ position < axis.outputExtent then
    let plan := plan1 axis batchGroups featureGroups channels
    let input : Input plan Int := fun batch channel spatial =>
      (batch.val : Int) * 100 + (channel.val : Int) * 10 + (spatial 0).val + 1
    let kernel : Kernel plan Int := fun _ _ _ _ spatial => ((spatial 0).val + 1 : Int) * scale
    some (convolve plan input kernel
      { batch := ⟨0, by change 0 < 1; decide⟩, batchGroup := ⟨batchGroup, valid.1⟩,
        featureGroup := ⟨featureGroup, valid.2.1⟩, feature := ⟨0, by change 0 < 1; decide⟩,
        spatial := fun _ => ⟨position, valid.2.2⟩ } + bias)
  else none

private def evaluate2 (position : Nat) : Option Int :=
  let axis := { baseAxis with inputExtent := 3 }
  let plan : Plan 2 :=
    { batchGroups := 1, featureGroups := 1, batchesPerGroup := 1,
      inputFeaturesPerGroup := 1, outputFeaturesPerGroup := 1, window := fun _ => axis }
  if valid : position < axis.outputExtent then
    some (convolve plan (fun _ _ spatial => (spatial 0).val * 10 + (spatial 1).val + 1)
      (fun _ _ _ _ _ => (1 : Int))
      { batch := ⟨0, by change 0 < 1; decide⟩, batchGroup := ⟨0, by change 0 < 1; decide⟩,
        featureGroup := ⟨0, by change 0 < 1; decide⟩, feature := ⟨0, by change 0 < 1; decide⟩,
        spatial := fun _ => ⟨position, valid⟩ })
  else none

private def evaluateFeature (feature : Nat) (scaled : Bool) : Option Int :=
  let axis := { baseAxis with inputExtent := 3, kernelExtent := 1 }
  let plan : Plan 1 :=
    { batchGroups := 1, featureGroups := 1, batchesPerGroup := 1,
      inputFeaturesPerGroup := 1, outputFeaturesPerGroup := 2, window := fun _ => axis }
  if valid : feature < 2 then
    some (convolve plan (fun _ _ spatial => ((spatial 0).val + 1 : Int))
      (fun _ _ outputFeature _ _ => (outputFeature.val + 1 : Int) *
        (if scaled then (outputFeature.val + 2 : Int) else 1))
      { batch := ⟨0, by change 0 < 1; decide⟩,
        batchGroup := ⟨0, by change 0 < 1; decide⟩,
        featureGroup := ⟨0, by change 0 < 1; decide⟩,
        feature := ⟨feature, valid⟩, spatial := fun _ => ⟨0, by
          norm_num [plan, axis, Plan.outputShape, Axis.outputExtent, dilatedExtent, baseAxis]⟩ })
  else none

private def evaluateNoSpatial : Int :=
  let plan : Plan 0 :=
    { batchGroups := 1, featureGroups := 1, batchesPerGroup := 1,
      inputFeaturesPerGroup := 2, outputFeaturesPerGroup := 1, window := Fin.elim0 }
  convolve plan (fun _ channel _ => (channel.val + 1 : Int))
    (fun _ _ _ channel _ => (channel.val + 3 : Int))
    { batch := ⟨0, by decide⟩, batchGroup := ⟨0, by decide⟩,
      featureGroup := ⟨0, by decide⟩, feature := ⟨0, by decide⟩, spatial := fun axis => Fin.elim0 axis }

#eval do
  let profiles : List (String × Option Int) :=
    [("plain", evaluate baseAxis 1 1 1 0 0 0),
     ("grouped", evaluate baseAxis 2 2 1 1 1 1),
     ("reversed", evaluate { baseAxis with reversed := true } 2 2 1 1 1 1),
     ("padded", evaluate { baseAxis with paddingLow := 1, paddingHigh := 1 } 1 1 1 0 0 0),
     ("cropped", evaluate { baseAxis with paddingLow := -1 } 1 1 1 0 0 0),
     ("base_dilation_even", evaluate
       { baseAxis with inputExtent := 3, baseDilation := 2, baseDilation_pos := by decide }
       1 1 1 0 0 0),
     ("base_dilation_hole", evaluate
       { baseAxis with inputExtent := 3, baseDilation := 2, baseDilation_pos := by decide }
       1 1 1 0 0 1),
     ("kernel_dilation", evaluate
       { baseAxis with kernelDilation := 2, kernelDilation_pos := by decide } 1 1 1 0 0 0),
     ("stride", evaluate { baseAxis with stride := 2, stride_pos := by decide } 1 1 1 0 0 1),
     ("empty_input_padded", evaluate
       { baseAxis with inputExtent := 0, paddingLow := 2, paddingHigh := 2 } 1 1 1 0 0 0),
     ("empty_kernel", evaluate { baseAxis with kernelExtent := 0 } 1 1 1 0 0 0),
     ("no_channels", evaluate baseAxis 1 1 0 0 0 0),
     ("two_channels", evaluate baseAxis 1 1 2 0 0 0),
     ("out_of_output_bounds", evaluate baseAxis 1 1 1 0 0 4),
     ("two_dimensional_low", evaluate2 0), ("two_dimensional_high", evaluate2 1),
     ("bias_scale_output", (evaluate baseAxis 2 2 1 1 1 1).map (fun value => (value + 5) * 3)),
     ("bias_scale_kernel", evaluate baseAxis 2 2 1 1 1 1 3 15),
     ("output_feature_zero", evaluateFeature 0 false),
     ("output_feature_one", evaluateFeature 1 false),
     ("output_feature_scaled", evaluateFeature 1 true),
     ("no_spatial_axes", some evaluateNoSpatial)]
  for (name, value) in profiles do
    match value with
    | some result => IO.println s!"CONV_MODEL case={name} value={result}"
    | none => IO.println s!"CONV_MODEL case={name} value=none"
