module

public import TensorRewrite.Theory.FullSpanWindowLemmas

/-! Exact ordered full-span windows as the existing reduction followed by logical reshape. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.FullSpanWindow

open Pilot

/-- All sampled values occur in exactly the existing reduction fiber's order. -/
theorem sampled_fiber {α : Type} (plan : Reduction.Plan)
    (input : Tensor (windowPlan plan).inputShape α)
    (output : Index (windowPlan plan).outputShape) :
    ((OrderedCoordinates.enumerate (windowPlan plan).kernelShape).map fun kernel =>
      input (sampleIndex plan output kernel)) =
    Reduction.fiberValues plan (fun index => input (inputIndex plan index))
      (outputIndex plan output) := by
  induction plan with
  | scalar => rfl
  | keep extent tail ih =>
    trans (List.finRange 1).flatMap fun head =>
      (OrderedCoordinates.enumerate (windowPlan tail).kernelShape).map fun kernel =>
        input (sampleIndex (.keep extent tail) output (Fin.cases head kernel))
    · exact OrderedCoordinates.enumerate_uncons_map
        (windowPlan (.keep extent tail)).kernelShape
        (fun kernel => input (sampleIndex (.keep extent tail) output kernel))
    · simp only [List.finRange_succ, List.finRange_zero, List.map_nil,
        List.flatMap_cons, List.flatMap_nil, List.append_nil]
      exact ih
        (fun index => input (Fin.cases
          (Fin.cast (kept_output_extent extent) (output ⟨0, Nat.zero_lt_succ _⟩)) index))
        (fun axis => output axis.succ)
  | reduce extent tail ih =>
    trans (List.finRange extent).flatMap fun head =>
      (OrderedCoordinates.enumerate (windowPlan tail).kernelShape).map fun kernel =>
        input (sampleIndex (.reduce extent tail) output (Fin.cases head kernel))
    · exact OrderedCoordinates.enumerate_uncons_map
        (windowPlan (.reduce extent tail)).kernelShape
        (fun kernel => input (sampleIndex (.reduce extent tail) output kernel))
    · change (List.finRange extent).flatMap (fun head => _) =
        (List.finRange extent).flatMap (fun head => _)
      congr 1
      funext head
      exact ih
        (fun index => input (Fin.cases head index))
        (fun axis => output axis.succ)

/-- The actual bounded sampler's value list equals the reduction list, independently of padding. -/
theorem values_fiber {α : Type} (plan : Reduction.Plan) (padding : α)
    (input : Tensor (windowPlan plan).inputShape α)
    (output : Index (windowPlan plan).outputShape) :
    ReductionWindow.values (windowPlan plan) padding input output =
      Reduction.fiberValues plan (fun index => input (inputIndex plan index))
        (outputIndex plan output) := by
  rw [← sampled_fiber plan input output]
  unfold ReductionWindow.values OrderedCoordinates.enumerate
  rw [List.map_map]
  apply List.map_congr_left
  intro position _
  simp only [Function.comp_def, ReductionWindow.contribution, sample_valid]

/-- Full-span windows equal reduction plus derived reshape for any operation and initializer. -/
theorem reduce_reshape {α : Type} (plan : Reduction.Plan) (operation : α → α → α)
    (initial padding : α) (input : Tensor (windowPlan plan).inputShape α) :
    ReductionWindow.reduce (windowPlan plan) operation initial padding input =
      Reshape.reshapeTensor
        (Reduction.reduceTensor plan operation initial (fun index => input (inputIndex plan index)))
        (windowPlan plan).outputShape (output_count plan).symm := by
  funext output
  change (ReductionWindow.values (windowPlan plan) padding input output).foldl operation initial = _
  rw [values_fiber]
  change _ = (Reduction.fiberValues plan (fun index => input (inputIndex plan index))
    (Reshape.reshapeIndex plan.outputShape (windowPlan plan).outputShape
      (output_count plan).symm output)).foldl operation initial
  rw [output_reshape]

/-- The same theorem on an original-shape tensor uses the proved inverse input transport. -/
theorem original_reduce_reshape {α : Type} (plan : Reduction.Plan) (operation : α → α → α)
    (initial padding : α) (input : Tensor plan.inputShape α) :
    ReductionWindow.reduce (windowPlan plan) operation initial padding
      (fun index => input (originalIndex plan index)) =
      Reshape.reshapeTensor (Reduction.reduceTensor plan operation initial input)
        (windowPlan plan).outputShape (output_count plan).symm := by
  rw [reduce_reshape]
  simp only [original_input]

end TensorRewrite.Theory.FullSpanWindow
