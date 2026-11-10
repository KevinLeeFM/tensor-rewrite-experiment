module

public import TensorRewrite.Pilot.Reduction
public import TensorRewrite.Pilot.ReshapeLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.Reduction

open LinearIndex

/-- Constant-size blocks concatenate to the product of block count and block size. -/
theorem length_flatMap_constant {α β : Type} (values : List α) (blocks : α → List β)
    (size : Nat) (constant : ∀ value, (blocks value).length = size) :
    (values.flatMap blocks).length = values.length * size := by
  induction values with
  | nil => simp only [List.flatMap_nil, List.length_nil, Nat.zero_mul]
  | cons value values ih =>
    simp only [List.flatMap_cons, List.length_append, List.length_cons, constant, ih,
      Nat.add_mul, Nat.one_mul, Nat.add_comm]

/-- Every enumerated fiber has exactly the product of reduced extents. -/
theorem fiberValues_length {α : Type} (plan : Plan) (input : Tensor plan.inputShape α)
    (output : Index plan.outputShape) :
    (fiberValues plan input output).length = plan.fiberCount := by
  induction plan with
  | scalar => rfl
  | keep extent tail ih => exact ih _ _
  | reduce extent tail ih =>
    change ((List.finRange extent).flatMap _).length = extent * tail.fiberCount
    have length := length_flatMap_constant (List.finRange extent)
      (fun coordinate => fiberValues tail (fun index => input (Fin.cases coordinate index)) output)
      tail.fiberCount (fun _ => ih _ _)
    simpa only [List.length_finRange] using length

/-- Input count factors into kept-axis count times reduced-axis count, even with zeros. -/
theorem elementCount_factor (plan : Plan) : elementCount plan.inputShape =
    elementCount plan.outputShape * plan.fiberCount := by
  induction plan with
  | scalar => rfl
  | keep extent tail ih =>
    change extent * elementCount tail.inputShape =
      (extent * elementCount tail.outputShape) * tail.fiberCount
    rw [ih, Nat.mul_assoc]
  | reduce extent tail ih =>
    change extent * elementCount tail.inputShape =
      elementCount tail.outputShape * (extent * tail.fiberCount)
    rw [ih]
    simp only [Nat.mul_assoc, Nat.mul_comm]

/-- A one-element fiber requires every reduced extent to be one. -/
theorem unitReducedAxes_of_fiberCount_one (plan : Plan) (one : plan.fiberCount = 1) :
    plan.UnitReducedAxes := by
  induction plan with
  | scalar => trivial
  | keep extent tail ih => exact ih one
  | reduce extent tail ih =>
    exact ⟨Nat.eq_one_of_mul_eq_one_right one, ih (Nat.eq_one_of_mul_eq_one_left one)⟩

/-- Equal nonempty input/output counts force singleton reduction fibers. -/
theorem fiberCount_one_of_sameCount (plan : Plan)
    (sameCount : elementCount plan.inputShape = elementCount plan.outputShape)
    (nonempty : 0 < elementCount plan.outputShape) : plan.fiberCount = 1 := by
  apply Nat.mul_left_cancel nonempty
  calc
    elementCount plan.outputShape * plan.fiberCount = elementCount plan.inputShape :=
      (elementCount_factor plan).symm
    _ = elementCount plan.outputShape * 1 := by simpa only [Nat.mul_one] using sameCount

/-- Removing unit axes preserves the logical element count. -/
theorem elementCount_eq_of_units (plan : Plan) (units : plan.UnitReducedAxes) :
    elementCount plan.inputShape = elementCount plan.outputShape := by
  induction plan with
  | scalar => rfl
  | keep extent tail ih =>
    change extent * elementCount tail.inputShape = extent * elementCount tail.outputShape
    rw [ih units]
  | reduce extent tail ih =>
    change extent * elementCount tail.inputShape = elementCount tail.outputShape
    rw [units.1, Nat.one_mul, ih units.2]

/-- Unit-axis fibers contain exactly the uniquely reconstructed input value. -/
theorem fiberValues_unit {α : Type} (plan : Plan) (units : plan.UnitReducedAxes)
    (input : Tensor plan.inputShape α) (output : Index plan.outputShape) :
    fiberValues plan input output = [input (plan.unitIndex units output)] := by
  induction plan with
  | scalar => rfl
  | keep extent tail ih => exact ih units _ _
  | reduce extent tail ih =>
    rcases units with ⟨rfl, units⟩
    simp only [fiberValues, List.finRange_succ, List.finRange_zero, List.map_nil,
      List.flatMap_cons, List.flatMap_nil, List.append_nil]
    exact ih units _ _

/-- Inserting zero unit coordinates preserves the dim0-major linear position. -/
theorem unitIndex_linearize_val (plan : Plan) (units : plan.UnitReducedAxes)
    (output : Index plan.outputShape) :
    (linearize plan.inputShape (plan.unitIndex units output)).val =
      (linearize plan.outputShape output).val := by
  induction plan with
  | scalar => rfl
  | keep extent tail ih =>
    have tailValues := ih units (fun axis => output axis.succ)
    have products := congrArg (fun count => (output ⟨0, Nat.zero_lt_succ _⟩).val * count)
      (elementCount_eq_of_units tail units)
    change (output ⟨0, Nat.zero_lt_succ _⟩).val * elementCount tail.inputShape +
        (linearize tail.inputShape
          (tail.unitIndex units (fun axis => output axis.succ))).val =
      (output ⟨0, Nat.zero_lt_succ _⟩).val * elementCount tail.outputShape +
        (linearize tail.outputShape (fun axis => output axis.succ)).val
    omega
  | reduce extent tail ih =>
    have tailValues := ih units.2 output
    change 0 * elementCount tail.inputShape +
      (linearize tail.inputShape (tail.unitIndex units.2 output)).val =
        (linearize tail.outputShape output).val
    omega

/-- The unit-axis reconstruction is precisely the already specified reshape map. -/
theorem unitIndex_eq_reshapeIndex (plan : Plan) (units : plan.UnitReducedAxes)
    (sameCount : elementCount plan.inputShape = elementCount plan.outputShape)
    (output : Index plan.outputShape) : plan.unitIndex units output =
      Reshape.reshapeIndex plan.inputShape plan.outputShape sameCount output := by
  calc
    plan.unitIndex units output = delinearize plan.inputShape
        (linearize plan.inputShape (plan.unitIndex units output)) :=
      (delinearize_linearize _ _).symm
    _ = _ := by
      unfold Reshape.reshapeIndex
      apply congrArg (delinearize plan.inputShape)
      apply Fin.ext
      exact unitIndex_linearize_val plan units output

end TensorRewrite.Pilot.Reduction
