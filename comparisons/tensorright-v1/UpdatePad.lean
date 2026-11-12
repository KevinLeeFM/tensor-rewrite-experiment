module

public import TensorRewrite.Theory.DynamicUpdate
public import TensorRewrite.Theory.SlicePadLemmas

/-! The paper's dynamic update of a constant tensor and zero-interior padding. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.UpdatePad

open Pilot Theory Theory.DynamicUpdate Theory.SlicePad

/-- The shape equation in the paper differs only in addition order. -/
theorem paper_shape {rank : Nat} (padding : Padding rank) (inner outer : Shape rank)
    (shape : ∀ axis, outer axis = inner axis + padding.low axis + padding.high axis) :
    outer = padding.outputShape inner := by
  funext axis
  have equality := shape axis
  simp only [Padding.outputShape]
  omega

/-- The paper's low padding determines the actual DynamicUpdateSlice window. -/
def padWindow {rank : Nat} (padding : Padding rank) (inner : Shape rank) :
    Window (padding.outputShape inner) inner where
  starts := fun axis => padding.low axis
  fits := by
    intro axis
    simp only [Padding.outputShape]
    omega

/-- The corresponding start is already in bounds and hence is never clamped. -/
theorem start_eq_low {rank : Nat} (padding : Padding rank) (inner : Shape rank)
    (axis : Fin rank) : (padWindow padding inner).start axis = padding.low axis := by
  unfold Window.start padWindow DynamicIndex.clampStart Padding.outputShape
  simp only
  omega

/-- The Pad and DynamicUpdateSlice membership predicates test the same interval. -/
theorem membership {rank : Nat} (padding : Padding rank) (inner : Shape rank)
    (index : Index (padding.outputShape inner)) :
    (∀ axis, (ReductionWindow.boundedIndex? (inner axis)
      ((index axis).val - (padding.low axis : Int))).isSome) ↔
      (∀ axis, (padWindow padding inner).start axis ≤ (index axis).val ∧
        (index axis).val < (padWindow padding inner).start axis + inner axis) := by
  simp only [bounded_isSome, start_eq_low]
  constructor <;> intro h axis <;> have bounds := h axis <;> omega

/-- `dyupslice/rule02`: update into a constant tensor equals actual edge Pad. -/
theorem update_eq_pad {rank : Nat} {α : Type} (padding : Padding rank)
    (inner : Shape rank) (fill : α) (input : Tensor inner α) :
    (padWindow padding inner).update (Tensor.constant fill) input =
      padding.tensor fill input := by
  funext index
  unfold Window.update Window.locate Padding.tensor Padding.input?
  by_cases inside : ∀ axis, (padWindow padding inner).start axis ≤ (index axis).val ∧
      (index axis).val < (padWindow padding inner).start axis + inner axis
  · have valid := (membership padding inner index).mpr inside
    rw [dite_eq_left inside, dite_eq_left valid]
    apply congrArg input
    funext axis
    apply Fin.ext
    have coordinate := bounded_value (inner axis)
      ((index axis).val - (padding.low axis : Int)) (valid axis)
    change (index axis).val - (padWindow padding inner).start axis =
      ((ReductionWindow.boundedIndex? (inner axis)
        ((index axis).val - (padding.low axis : Int))).get (valid axis)).val
    have start := start_eq_low padding inner axis
    have bounds := inside axis
    omega
  · have invalid : ¬ (∀ axis, (ReductionWindow.boundedIndex? (inner axis)
        ((index axis).val - (padding.low axis : Int))).isSome) := by
      intro valid
      exact inside ((membership padding inner index).mp valid)
    rw [dite_eq_right inside, dite_eq_right invalid]
    rfl

#print axioms paper_shape
#print axioms start_eq_low
#print axioms membership
#print axioms update_eq_pad

end TensorRewrite.PaperComparison.UpdatePad
