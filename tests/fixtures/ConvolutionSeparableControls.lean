import TensorRewriteTheory

open TensorRewrite.Pilot
open TensorRewrite.Theory.Convolution
open TensorRewrite.Theory.ConvolutionSeparable

private def mixedAxis (extent : Nat) (spanning reversed : Bool) : Axis := {
  inputExtent := extent
  kernelExtent := if spanning then extent else 1
  stride := 1
  baseDilation := 1
  kernelDilation := 1
  paddingLow := 0
  paddingHigh := 0
  reversed := reversed
  stride_pos := by decide
  baseDilation_pos := by decide
  kernelDilation_pos := by decide
}

private def mixedPlan {rank : Nat} (shape : Shape rank)
    (spanning reversed : Fin rank → Bool) (batchGroups batches featureGroups features : Nat) :
    Plan rank := {
  batchGroups := batchGroups
  batchesPerGroup := batches
  featureGroups := featureGroups
  inputFeaturesPerGroup := 1
  outputFeaturesPerGroup := features
  window := fun axis => mixedAxis (shape axis) (spanning axis) (reversed axis)
}

private theorem mixedPlan_valid {rank : Nat} (shape : Shape rank)
    (spanning reversed : Fin rank → Bool) (batchGroups batches featureGroups features : Nat) :
    IsSeparable (mixedPlan shape spanning reversed batchGroups batches featureGroups features) := by
  intro axis
  refine ⟨rfl, rfl, rfl, rfl, rfl, ?_⟩
  cases mode : spanning axis <;>
    simp [mixedPlan, mixedAxis, mode, Axis.outputExtent]

private def evaluate {rank : Nat} (shape : Shape rank)
    (spanning reversed : Fin rank → Bool) (batchGroups batches featureGroups features : Nat) :
    Nat × Nat × List (Int × Int) :=
  let plan := mixedPlan shape spanning reversed batchGroups batches featureGroups features
  let valid := mixedPlan_valid shape spanning reversed batchGroups batches featureGroups features
  let input : Input plan Int := fun batch channel spatial =>
    (batch.val : Int) * 100 + (channel.val : Int) * 10 + 1 +
      (((List.finRange rank).map fun axis =>
        (spatial axis).val * 10 ^ (rank - 1 - axis.val)).sum : Nat)
  let kernel : Kernel plan Int := fun group _ feature _ spatial =>
    (group.val + 1 : Int) * (feature.val + 1 : Int) *
      ((LinearIndex.linearize plan.kernelShape spatial).val + 1 : Int)
  let values := (List.finRange batchGroups).flatMap fun group =>
    (List.finRange batches).flatMap fun batch =>
      (List.finRange featureGroups).flatMap fun featureGroup =>
        (List.finRange features).flatMap fun feature =>
          (List.finRange (LinearIndex.elementCount plan.outputShape)).map fun position =>
            let output : OutputIndex plan := {
              batch := batch
              batchGroup := group
              featureGroup := featureGroup
              feature := feature
              spatial := LinearIndex.delinearize plan.outputShape position
            }
            (convolve plan input kernel output,
              productReduction plan (derive_geometry plan valid) rfl input kernel output)
  (Fintype.card (ReducedAxis plan), Fintype.card (ReducedIndex plan), values)

#eval do
  let profiles : List (String × (Nat × Nat × List (Int × Int))) :=
    [("spanning", evaluate (fun _ : Fin 1 => 3) (fun _ => true) (fun _ => false) 1 1 1 1),
     ("spanning_reversed", evaluate (fun _ : Fin 1 => 3)
       (fun _ => true) (fun _ => true) 1 1 1 1),
     ("mixed_grouped", evaluate (fun axis : Fin 2 => if axis.val = 0 then 3 else 4)
       (fun axis => axis.val == 1) (fun _ => false) 2 2 2 2),
     ("mixed_grouped_reversed", evaluate (fun axis : Fin 2 => if axis.val = 0 then 3 else 4)
       (fun axis => axis.val == 1) (fun axis => axis.val == 1) 2 2 2 2),
     ("three_axes", evaluate (fun axis : Fin 3 => if axis.val = 0 then 2 else
         if axis.val = 1 then 3 else 4)
       (fun axis => axis.val == 1) (fun axis => axis.val == 1) 1 1 1 2),
     ("all_spanning", evaluate (fun axis : Fin 2 => if axis.val = 0 then 2 else 3)
       (fun _ => true) (fun _ => true) 1 1 1 1),
     ("all_unit", evaluate (fun axis : Fin 2 => if axis.val = 0 then 2 else 3)
       (fun _ => false) (fun _ => true) 1 1 1 1),
     ("rank_zero", evaluate (fun axis : Fin 0 => Fin.elim0 axis)
       (fun _ => false) (fun _ => false) 1 1 1 1),
     ("empty_kernel", evaluate (fun _ : Fin 1 => 0)
       (fun _ => true) (fun _ => false) 1 1 1 1),
     ("empty_output", evaluate (fun _ : Fin 1 => 0)
       (fun _ => false) (fun _ => false) 1 1 1 1),
     ("no_batch_groups", evaluate (fun _ : Fin 1 => 3)
       (fun _ => true) (fun _ => false) 0 1 1 1)]
  for (name, (axes, domain, values)) in profiles do
    IO.println s!"SEP_COUNT case={name} axes={axes} domain={domain} outputs={values.length}"
    for ((original, reduced), index) in values.zipIdx do
      IO.println s!"SEP case={name} index={index} conv={original} product={reduced}"
