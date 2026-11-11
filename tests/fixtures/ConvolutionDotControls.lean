import TensorRewriteTheory

open TensorRewrite.Pilot
open TensorRewrite.Theory.Convolution
open TensorRewrite.Theory.ConvolutionPointwise
open TensorRewrite.Theory.ConvolutionDot

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
    (positive : 0 < dilation) (reverse matrixOrder : Bool) : List (Int × Int × Nat × Nat) :=
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
  let compute (output : OutputIndex plan) (index : Index (matrixPlan plan).outputShape) :=
    (convolve plan input kernel output,
      Contraction.dotTensor (matrixPlan plan) (· + ·) 0 (· * ·) id
        (lhsMatrix plan input output.batchGroup output.featureGroup)
        (rhsMatrix plan (fun axis => (valid axis).unitKernel) kernel
          output.batchGroup output.featureGroup) index,
      (index 0).val, (index 1).val)
  if matrixOrder then
    (List.finRange batchGroups).flatMap fun group =>
      (List.finRange featureGroups).flatMap fun featureGroup =>
        (List.finRange (rowCount plan)).flatMap fun row =>
          (List.finRange features).map fun feature =>
            let index : Index (matrixPlan plan).outputShape :=
              Contraction.appendIndex (fun axis => Fin.elim0 axis)
                (Contraction.appendIndex (fun _ => row) (fun _ => feature))
            compute (convolutionOutput plan (output_shape_eq plan valid) group featureGroup index)
              index
  else
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
              compute output (dotOutput plan (output_shape_eq plan valid) output)

#eval do
  let profiles : List (String × (Bool → List (Int × Int × Nat × Nat))) :=
    [("one_channel", evaluate (fun _ : Fin 1 => 3) 1 1 1 1 1 1 (by decide) false),
     ("grouped_two_dimensional", evaluate (fun axis : Fin 2 => if axis.val = 0 then 2 else 3)
       3 2 2 2 2 1 (by decide) false),
     ("reversed_kernel_dilation", evaluate (fun _ : Fin 1 => 3)
       2 1 1 1 2 7 (by decide) true),
     ("zero_channels", evaluate (fun _ : Fin 1 => 3) 0 1 1 1 1 1 (by decide) false),
     ("empty_spatial", evaluate (fun _ : Fin 2 => 0) 2 1 1 1 1 1 (by decide) false),
     ("rank_zero", evaluate (fun axis : Fin 0 => Fin.elim0 axis)
       2 1 1 1 1 1 (by decide) false),
     ("rank_zero_no_channels", evaluate (fun axis : Fin 0 => Fin.elim0 axis)
       0 1 1 1 1 1 (by decide) false),
     ("no_batch_groups", evaluate (fun _ : Fin 1 => 3) 2 0 1 1 1 1 (by decide) false),
     ("no_batches", evaluate (fun _ : Fin 1 => 3) 2 1 0 1 1 1 (by decide) false),
     ("no_feature_groups", evaluate (fun _ : Fin 1 => 3) 2 1 1 0 1 1 (by decide) false),
     ("no_output_features", evaluate (fun _ : Fin 1 => 3) 2 1 1 1 0 1 (by decide) false)]
  for (name, profile) in profiles do
    for matrixOrder in ([false, true] : List Bool) do
      let direction := if (matrixOrder : Bool) then "matrix" else "convolution"
      let values : List (Int × Int × Nat × Nat) :=
        (profile : Bool → List (Int × Int × Nat × Nat)) matrixOrder
      IO.println s!"DOT_COUNT case={name} direction={direction} count={values.length}"
      for ((original, result, row, feature), index) in values.zipIdx do
        IO.println (s!"DOT case={name} direction={direction} index={index}" ++
          s!" conv={original} dot={result} row={row} feature={feature}")
