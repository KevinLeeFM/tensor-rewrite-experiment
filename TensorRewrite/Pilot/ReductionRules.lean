module

public import TensorRewrite.Pilot.ReductionLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.Reduction

open LinearIndex

/-- A zero-element input produces the actual initializer at every output coordinate. -/
theorem reduceTensor_empty_input {α : Type} (plan : Plan) (operation : α → α → α)
    (initial : α) (input : Tensor plan.inputShape α)
    (empty : elementCount plan.inputShape = 0) :
    reduceTensor plan operation initial input = Tensor.constant initial := by
  funext output
  have positive := Nat.zero_lt_of_lt (linearize plan.outputShape output).isLt
  have zero : elementCount plan.outputShape * plan.fiberCount = 0 :=
    (elementCount_factor plan).symm.trans empty
  have countZero : plan.fiberCount = 0 := by
    rcases Nat.mul_eq_zero.mp zero with h | h
    · omega
    · exact h
  have valuesEmpty := List.eq_nil_of_length_eq_zero
    ((fiberValues_length plan input output).trans countZero)
  unfold reduceTensor
  rw [valuesEmpty]
  rfl

/-- Empty output has the initializer broadcast's logical values, even without a reducer law. -/
theorem reduceTensor_empty_output {α : Type} (plan : Plan) (operation : α → α → α)
    (initial : α) (input : Tensor plan.inputShape α)
    (empty : elementCount plan.outputShape = 0) :
    reduceTensor plan operation initial input = Tensor.constant initial :=
  Reshape.tensor_eq_of_empty empty _ _

/-- Equal element counts eliminate reduction only with the actual initializer's identity law. -/
theorem reduceTensor_sameCount {α : Type} (plan : Plan) (operation : α → α → α)
    (initial : α) (leftIdentity : ∀ value, operation initial value = value)
    (input : Tensor plan.inputShape α)
    (sameCount : elementCount plan.inputShape = elementCount plan.outputShape) :
    reduceTensor plan operation initial input =
      Reshape.reshapeTensor input plan.outputShape sameCount := by
  by_cases empty : elementCount plan.outputShape = 0
  · exact Reshape.tensor_eq_of_empty empty _ _
  · have units := unitReducedAxes_of_fiberCount_one plan
      (fiberCount_one_of_sameCount plan sameCount (Nat.pos_of_ne_zero empty))
    funext output
    unfold reduceTensor
    rw [fiberValues_unit plan units]
    change operation initial (input (plan.unitIndex units output)) = _
    rw [leftIdentity]
    exact congrArg input (unitIndex_eq_reshapeIndex plan units sameCount output)

end TensorRewrite.Pilot.Reduction
