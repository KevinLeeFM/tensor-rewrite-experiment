module

public import SignedPadSpec

public section

set_option autoImplicit false

namespace RevisedBenchmark.HandlePad

open TensorRewrite.Pilot TensorRewrite.PaperComparison.SignedPad

/-- The constructor preserves the original low edge and changes spacing only on singleton axes. -/
theorem unit_interior : UnitInteriorGoal := by
  intro rank inputShape outputShape α params _ _ fill input
  apply TensorRewrite.PaperComparison.SignedPad.unit_interior params (clearUnitInterior params)
  · intro axis
    rfl
  · intro axis
    change params.interior axis =
      (if 0 < params.interior axis ∧ inputShape axis = 1 then 0 else params.interior axis) ∨
      inputShape axis = 1
    split
    next clears => exact Or.inr clears.2
    next => exact Or.inl rfl

/-- A zero-extent axis prevents any successful sample, even when the output has coordinates. -/
theorem empty_input : EmptyInputGoal := by
  intro rank inputShape outputShape α params empty fill input
  obtain ⟨axis, extentZero⟩ := empty
  funext output
  unfold tensor
  cases chosen : selected params output with
  | none => rfl
  | some index => exact Fin.elim0 (Fin.cast extentZero (index axis))

#print axioms unit_interior
#print axioms empty_input

end RevisedBenchmark.HandlePad
