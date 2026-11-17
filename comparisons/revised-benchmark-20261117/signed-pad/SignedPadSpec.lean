module

public import SignedPadHistorical

@[expose] public section

set_option autoImplicit false

namespace RevisedBenchmark.HandlePad

open TensorRewrite.Pilot TensorRewrite.PaperComparison.SignedPad

/-- The earlier HandlePad branch matches if any input extent is zero. -/
def IsEmptyInput {rank : Nat} (shape : Shape rank) : Prop :=
  ∃ axis, shape axis = 0

/-- A loop iteration clears interior padding exactly on a singleton axis with
positive old interior. -/
def ClearsInterior {rank : Nat} {inputShape outputShape : Shape rank}
    (params : Params inputShape outputShape) (axis : Fin rank) : Prop :=
  0 < params.interior axis ∧ inputShape axis = 1

/-- A matched unit-interior replacement preserves the signed edges and clears
only the selected interiors. The original output shape remains well-formed. -/
def clearUnitInterior {rank : Nat} {inputShape outputShape : Shape rank}
    (params : Params inputShape outputShape) : Params inputShape outputShape where
  low := params.low
  high := params.high
  interior axis := if 0 < params.interior axis ∧ inputShape axis = 1
    then 0 else params.interior axis
  shape axis := by
    rw [params.shape axis]
    split
    next clears =>
      rw [clears.2]
      exact extent_unit (params.low axis) (params.high axis) (params.interior axis) 0
    next => rfl

/-- Logical values of the old Pad and its exact source-selected replacement,
on the unit-interior branch after the empty-input dispatch. -/
def UnitInteriorGoal : Prop :=
  ∀ {rank : Nat} {inputShape outputShape : Shape rank} {α : Type}
    (params : Params inputShape outputShape)
    (_nonempty : ¬ IsEmptyInput inputShape)
    (_cleared : ∃ axis, ClearsInterior params axis)
    (fill : α) (input : Tensor inputShape α),
    tensor params fill input = tensor (clearUnitInterior params) fill input

/-- Logical values of the old Pad and its scalar Broadcast replacement on the
empty-input branch. The output need not be empty. -/
def EmptyInputGoal : Prop :=
  ∀ {rank : Nat} {inputShape outputShape : Shape rank} {α : Type}
    (params : Params inputShape outputShape) (_empty : IsEmptyInput inputShape)
    (fill : α) (input : Tensor inputShape α),
    tensor params fill input = Tensor.constant fill

end RevisedBenchmark.HandlePad
