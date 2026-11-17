module
public import Spec

/-! Concrete legal nontrivial input and false-replacement controls, frozen preproof. -/
@[expose] public section
set_option autoImplicit false
namespace TensorRewrite.Heldout.UnitReverse.Controls
open TensorRewrite.Pilot
open TensorRewrite.Heldout.UnitReverse

/-- Two retained nonunit axes. -/
def inputShape : Shape 2 := fun i => if i.val = 0 then 2 else 3
/-- Insert unit axes before, between and after retained axes. -/
def outputShape : Shape 5 := fun i => if i.val = 1 then 2 else if i.val = 3 then 3 else 1

/-- A legal nontrivial arbitrary-axis insertion instance. -/
def plan : UnitInsertion inputShape outputShape where
  keptAxis := fun i => ⟨2 * i.val + 1, by have := i.isLt; omega⟩
  increasing := by
    intro i j h
    change i.val < j.val at h
    change 2 * i.val + 1 < 2 * j.val + 1
    omega
  extent := by
    intro i
    have bound := i.isLt
    by_cases first : i.val = 0
    · simp [inputShape, outputShape, first]
    · have second : i.val = 1 := by omega
      simp [inputShape, outputShape, second]
  insertedUnit := by
    intro j absent
    by_cases first : j.val = 1
    · exfalso
      apply absent ⟨0, by decide⟩
      apply Fin.ext
      exact first.symm
    · by_cases second : j.val = 3
      · exfalso
        apply absent ⟨1, by decide⟩
        apply Fin.ext
        exact second.symm
      · simp [outputShape, first, second]

/-- Every output axis has a valid zero coordinate. -/
def zeroIndex : Index outputShape :=
  fun i => ⟨0, by
    by_cases first : i.val = 1
    · simp [outputShape, first]
    · by_cases second : i.val = 3 <;> simp [outputShape, first, second]⟩

/-- Coordinate-sensitive data detects reversing the wrong retained axis. -/
def input : Tensor inputShape Nat :=
  fun index => 10 * (index ⟨0, by decide⟩).val + (index ⟨1, by decide⟩).val

/-- Reverse output axis one, which must map to input axis zero. -/
def selected : Fin 5 → Bool := fun i => i.val == 1

/-- Faulty unadjusted remapping reverses input axis one instead. -/
def wrongAxes : Fin 2 → Bool := fun i => i.val == 1

/-- The shape/guard has a real nontrivial observation. -/
example : Tensor.reverse selected (reshape plan input) zeroIndex = 10 := by decide
/-- A wrong dimension remapping gives a different value. -/
example : reshape plan (Tensor.reverse wrongAxes input) zeroIndex = 2 := by decide
/-- Omitting the reversal also gives a different observation. -/
example : reshape plan input zeroIndex = 0 := by decide

/-- A well-formed false equality, independently refuted by the observation above. -/
def WrongGoal : Prop :=
  Tensor.reverse selected (reshape plan input) zeroIndex =
    reshape plan (Tensor.reverse wrongAxes input) zeroIndex

/-- The negative-control proposition is false, rather than ill-typed. -/
theorem wrong_goal_false : ¬ WrongGoal := by unfold WrongGoal; decide

end TensorRewrite.Heldout.UnitReverse.Controls
