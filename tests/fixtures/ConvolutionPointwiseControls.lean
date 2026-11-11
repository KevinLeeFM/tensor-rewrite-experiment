import TensorRewriteTheory

open TensorRewrite.Pilot
open TensorRewrite.Theory.Convolution
open TensorRewrite.Theory.ConvolutionPointwise

private def pointAxis (extent dilation : Nat) (positive : 0 < dilation) (reverse : Bool) : Axis := {
  inputExtent := extent
  kernelExtent := 1
  stride := 1
  baseDilation := 1
  kernelDilation := dilation
  paddingLow := 0
  paddingHigh := 0
  reversed := reverse
  stride_pos := by decide
  baseDilation_pos := by decide
  kernelDilation_pos := positive
}

private def pointPlan {rank : Nat} (shape : Shape rank)
    (channels batchGroups batches featureGroups features dilation : Nat)
    (positive : 0 < dilation) (reverse : Bool) : Plan rank := {
  batchGroups := batchGroups
  featureGroups := featureGroups
  batchesPerGroup := batches
  inputFeaturesPerGroup := channels
  outputFeaturesPerGroup := features
  window := fun axis => pointAxis (shape axis) dilation positive reverse
}

private theorem pointPlan_valid {rank : Nat} (shape : Shape rank)
    (channels batchGroups batches featureGroups features dilation : Nat)
    (positive : 0 < dilation) (reverse : Bool) :
    IsPointwise (pointPlan shape channels batchGroups batches featureGroups features
      dilation positive reverse) :=
  fun _ => ⟨rfl, rfl, rfl, rfl, rfl⟩

private def evaluate {rank : Nat} (shape : Shape rank)
    (channels batchGroups batches featureGroups features dilation : Nat)
    (positive : 0 < dilation) (reverse : Bool) : List (Int × Int) :=
  let plan := pointPlan shape channels batchGroups batches featureGroups features
    dilation positive reverse
  let valid := pointPlan_valid shape channels batchGroups batches featureGroups features
    dilation positive reverse
  let input : Input plan Int := fun batch channel spatial =>
    (batch.val : Int) * 100 + (channel.val : Int) * 10 + 1 +
      (((List.finRange rank).map fun axis =>
        (spatial axis).val * 10 ^ (rank - 1 - axis.val)).sum : Nat)
  let kernel : Kernel plan Int := fun group _ feature channel _ =>
    (group.val + 1 : Int) * (feature.val + 1 : Int) * (channel.val + 3 : Int)
  (List.finRange batchGroups).flatMap fun group =>
    (List.finRange batches).flatMap fun batch =>
      (List.finRange featureGroups).flatMap fun featureGroup =>
        (List.finRange features).flatMap fun feature =>
          (List.finRange (LinearIndex.elementCount shape)).map fun position =>
            let spatial := LinearIndex.delinearize shape position
            let output : OutputIndex plan := {
              batch := batch
              batchGroup := group
              featureGroup := featureGroup
              feature := feature
              spatial := fun axis => Fin.cast
                (output_extent_eq (plan.window axis) (valid axis)).symm (spatial axis)
            }
            (convolve plan input kernel output,
              channelSum plan (output_shape_eq plan valid)
                (fun axis => (valid axis).unitKernel) input kernel output)

#eval do
  let profiles : List (String × List (Int × Int)) :=
    [("one_channel", evaluate (fun _ : Fin 1 => 3) 1 1 1 1 1 1 (by decide) false),
     ("grouped_two_dimensional", evaluate (fun _ : Fin 2 => 2)
       3 2 2 2 2 1 (by decide) false),
     ("reversed_kernel_dilation", evaluate (fun _ : Fin 1 => 3)
       2 1 1 1 2 7 (by decide) true),
     ("zero_channels", evaluate (fun _ : Fin 1 => 3) 0 1 1 1 1 1 (by decide) false),
     ("empty_spatial", evaluate (fun _ : Fin 2 => 0) 2 1 1 1 1 1 (by decide) false),
     ("rank_zero", evaluate (fun axis : Fin 0 => Fin.elim0 axis)
       2 1 1 1 1 1 (by decide) false),
     ("rank_zero_no_channels", evaluate (fun axis : Fin 0 => Fin.elim0 axis)
       0 1 1 1 1 1 (by decide) false),
     ("no_batch_groups", evaluate (fun _ : Fin 1 => 3) 2 0 1 1 1 1 (by decide) false)]
  for (name, values) in profiles do
    IO.println s!"POINTWISE_COUNT case={name} count={values.length}"
    for ((original, reduced), index) in values.zipIdx do
      IO.println s!"POINTWISE case={name} index={index} conv={original} channels={reduced}"
