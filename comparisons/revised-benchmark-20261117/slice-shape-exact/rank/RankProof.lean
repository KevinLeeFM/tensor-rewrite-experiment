module
public import RankSpec
import SliceShapeExactProof

public section
set_option autoImplicit false
namespace TensorRewrite.Pilot.SliceShape.RankExact
open Exact

/-- Combine the checked axis classification and coordinate equality pointwise. -/
theorem stride : StrideGoal := by
  intro r s t a v
  have hs := fun k => removeRedundantStride_shape (s k) (t k) (a k) (v k)
  constructor
  · exact ⟨fun w k => (hs k).1 (w k), fun g k => (hs k).2 (g k)⟩
  intro w α x
  funext j
  apply congrArg x
  funext k
  apply Fin.ext
  have h := removeRedundantStride_coordinate (s k) (t k) (a k) (v k)
    ((hs k).1 (w k)) (j k) (by omega) (by have := (j k).isLt; omega)
  exact congrArg Int.toNat (by simpa only [Int.mul_comm] using h.symm)

/-- Reverse exactly the selected axes, before or after the valid transformed slice. -/
theorem reverse : ReverseGoal := by
  intro r s t a v mask
  have hs := fun k => reorderReverse_shape (s k) (t k) (a k) (v k)
  constructor
  · constructor
    · intro w k hk
      exact (hs k).1 (by simpa [reordered, hk] using w k)
    · intro g k
      cases hk : mask k with
      | false => simpa [reordered, hk] using v k
      | true => simpa [reordered, hk] using (hs k).2 (g k hk)
  intro w α x
  funext j
  apply congrArg x
  funext k
  apply Fin.ext
  cases hk : mask k with
  | false => simp [Tensor.reverseIndex, IndexMaps.sliceIndex, reordered, hk]
  | true =>
    have guard := (hs k).1 (by simpa [reordered, hk] using w k)
    have h := reorderReverse_coordinate (s k) (t k) (a k) (v k) guard
      (j k) (by omega) (by have := (j k).isLt; omega)
    have hj := (j k).isLt
    have hb := coordinate_bounds (v k) (j k) (by omega) (by omega)
    simp only [Tensor.reverseIndex, IndexMaps.sliceIndex, reordered, hk, ite_true, Fin.rev]
    have hm : (((t k - ((j k).val + 1) : Nat) : Int)) = (t k : Int) - 1 - (j k : Int) := by omega
    simp only [hm]
    rw [Int.mul_comm (a k).stride] at hb
    rw [Int.mul_comm (reorderReverse _ _).stride, h, Int.mul_comm (a k).stride] <;> omega

/-! A two-axis tensor with mixed mask, distinguishable values, and a legal slice.
Ignoring the mask on the replacement changes the observed value. -/
private def ctlInput : Shape 2 := fun _ => 5
private def ctlOutput : Shape 2 := fun _ => 2
private def ctlAxis : Fin 2 → Axis := fun _ => ⟨0, 4, 2⟩
private def ctlMask (k : Fin 2) : Bool := k == 0
private def ctlTensor : Tensor ctlInput Nat := fun i => (i 0).val * 10 + (i 1).val
private def ctlIndex : Index ctlOutput := fun _ => ⟨0, by decide +revert⟩
private theorem ctlValid : Legal ctlInput ctlOutput ctlAxis := fun _ => by decide +revert
private theorem ctlReordered : Legal ctlInput ctlOutput (reordered ctlInput ctlAxis ctlMask) := by
  intro k
  cases h : ctlMask k <;> simp only [reordered, h, Bool.false_eq_true, ite_false, ite_true, ctlInput, ctlOutput, ctlAxis] <;> decide

example : sliced ctlAxis ctlValid (Tensor.reverse ctlMask ctlTensor) ctlIndex = 40 := by decide
example : Tensor.reverse ctlMask (sliced _ ctlReordered ctlTensor) ctlIndex = 40 := by decide
example : sliced _ ctlReordered ctlTensor ctlIndex = 20 := by decide

/-! One empty non-unit original axis makes stride removal illegal. Reverse is
legal when that axis is unselected and illegal when it is selected. -/
private def emptyAxis : Fin 2 → Axis := fun k => if k == 0 then ⟨2, 2, 2⟩ else ⟨0, 2, 1⟩
private def emptyShape : Shape 2 := fun k => if k == 0 then 0 else 2
example : Legal ctlInput emptyShape emptyAxis := by
  intro k
  by_cases h : (k == 0) = true <;> simp [emptyShape, emptyAxis, h, ctlInput] <;> decide
example : ¬ Legal ctlInput emptyShape (fun k => removeRedundantStride (emptyAxis k)) := by
  intro w
  have hw := w 0
  exact (by decide : ¬ IsWellFormed 5 0 (removeRedundantStride ⟨2,2,2⟩)) hw
example : Legal ctlInput emptyShape (reordered ctlInput emptyAxis (fun k => !(k == 0))) := by
  intro k
  by_cases h : (k == 0) = true <;> simp [reordered, emptyShape, emptyAxis, h, ctlInput] <;> decide
example : ¬ Legal ctlInput emptyShape (reordered ctlInput emptyAxis ctlMask) := by
  intro w
  exact (by decide : ¬ IsWellFormed 5 0 (reorderReverse 5 ⟨2,2,2⟩)) (w 0)

#print axioms stride
#print axioms reverse
end TensorRewrite.Pilot.SliceShape.RankExact
