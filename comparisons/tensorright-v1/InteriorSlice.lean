module

public import TensorRewrite.Theory.PadWindowLemmas
public import TensorRewrite.Pilot.IndexMapLemmas

/-! Slice of the occupied points of a nonnegative, interior-padded tensor. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.InteriorSlice

open Pilot Theory Theory.PadWindow

/-- The existing Pad extent is the paper's size, edge and interior formula, including size zero. -/
theorem paper_pad_extent (padding : PaddingAxis) :
    (padding.outputExtent : Int) = (padding.low : Int) + padding.high + padding.inputExtent +
      max 0 ((padding.inputExtent : Int) - 1) * ((padding.spacing : Int) - 1) := by
  by_cases empty : padding.inputExtent = 0
  · simp [PaddingAxis.outputExtent, Convolution.dilatedExtent, empty]
  · have positive : 0 < padding.inputExtent := Nat.pos_of_ne_zero empty
    have maximum : max (0 : Int) ((padding.inputExtent : Int) - 1) =
        (padding.inputExtent : Int) - 1 := by omega
    simp only [PaddingAxis.outputExtent, Int.natCast_add, maximum,
      dilated_extent_nonempty padding.inputExtent padding.spacing positive]
    ring

/-- `slice/rule04`: sampling exactly the occupied Pad points recovers the input. -/
theorem slice_occupied {rank : Nat} {α : Type} (plan : Plan rank)
    (axes : Fin rank → SliceShape.Axis)
    (valid : ∀ axis, SliceShape.IsWellFormed (plan.paddedShape axis) (plan.inputShape axis)
      (axes axis))
    (starts : ∀ axis, (axes axis).start = (plan.padding axis).low)
    (strides : ∀ axis, (axes axis).stride = (plan.padding axis).spacing)
    (fill : α) (input : Tensor plan.inputShape α) :
    (fun output => pad plan fill input (IndexMaps.sliceIndex axes valid output)) = input := by
  funext output
  have samples : ∀ axis, (plan.padding axis).sample?
      (IndexMaps.sliceIndex axes valid output axis) = some (output axis) := by
    intro axis
    apply (pad_sample_iff _ _ _).mpr
    rw [IndexMaps.sliceIndex_val, starts axis, strides axis]
    ring
  have inPad : ∀ axis, ((plan.padding axis).sample?
      (IndexMaps.sliceIndex axes valid output axis)).isSome := by
    intro axis
    rw [samples axis]
    rfl
  unfold pad padIndex?
  rw [dite_eq_left inPad]
  apply congrArg input
  funext axis
  simp only [samples]
  rfl

#print axioms paper_pad_extent
#print axioms slice_occupied

end TensorRewrite.PaperComparison.InteriorSlice
