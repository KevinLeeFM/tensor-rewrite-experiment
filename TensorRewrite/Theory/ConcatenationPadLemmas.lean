module

public import TensorRewrite.Theory.ConcatenationGraphLemmas

/-! The existing Pad operator's actual bounded membership and data values at selected-axis edges. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Concatenation

open Pilot

/-- Actual multidimensional Pad membership is exactly the selected-axis interior interval. -/
theorem edgePadding_inside_iff {rank extent : Nat} (frame : Frame rank) (low high : Nat)
    (index : Index (frame.shape (low + extent + high))) :
    (∀ axis, (ReductionWindow.boundedIndex? (frame.shape extent axis)
      (((ShapeTransport.indexAlong (edgePadding_shape frame low high) index axis).val : Int) -
        (frame.edgePadding low high).low axis)).isSome) ↔
      low ≤ (frame.position index).val ∧ (frame.position index).val < low + extent := by
  constructor
  · intro valid
    have selected := (SlicePad.bounded_isSome _ _).mp (valid frame.axis)
    simp [Frame.shape, Frame.edgePadding, ShapeTransport.indexAlong, Fin.cast] at selected
    change low ≤ (index frame.axis).val ∧ (index frame.axis).val < low + extent
    omega
  · intro inside axis
    apply (SlicePad.bounded_isSome _ _).mpr
    by_cases same : axis = frame.axis
    · subst axis
      change low ≤ (index frame.axis).val ∧ (index frame.axis).val < low + extent at inside
      have arithmetic : 0 ≤ ((index frame.axis).val : Int) - low ∧
          ((index frame.axis).val : Int) - low < extent := by omega
      simpa [Frame.shape, Frame.edgePadding, ShapeTransport.indexAlong, Fin.cast] using arithmetic
    · have bounded : (index axis).val < frame.extents axis := by
        simpa only [Frame.shape, ite_eq_right same] using (index axis).isLt
      simp [Frame.shape, Frame.edgePadding, ShapeTransport.indexAlong, Fin.cast, same]
      omega

/-- Shape-transported Pad reads the actual shifted input inside and exactly the fill outside. -/
theorem edgePadding_value {rank extent : Nat} {α : Type} (frame : Frame rank)
    (low high : Nat) (fill : α) (input : Tensor (frame.shape extent) α)
    (index : Index (frame.shape (low + extent + high))) :
    ShapeTransport.tensorAlong (edgePadding_shape frame low high)
        ((frame.edgePadding low high).tensor fill input) index =
      if inside : low ≤ (frame.position index).val ∧ (frame.position index).val < low + extent then
        input (frame.withPosition index ⟨(frame.position index).val - low, by omega⟩)
      else fill := by
  unfold ShapeTransport.tensorAlong SlicePad.Padding.tensor SlicePad.Padding.input?
  by_cases inside : low ≤ (frame.position index).val ∧ (frame.position index).val < low + extent
  · have valid := (edgePadding_inside_iff frame low high index).mpr inside
    rw [dite_eq_left valid, dite_eq_left inside]
    apply congrArg input
    funext axis
    apply Fin.ext
    have coordinate := SlicePad.bounded_value (frame.shape extent axis)
      (((ShapeTransport.indexAlong (edgePadding_shape frame low high) index axis).val : Int) -
        (frame.edgePadding low high).low axis) (valid axis)
    by_cases same : axis = frame.axis
    · subst axis
      simp [Frame.shape, Frame.edgePadding, Frame.withPosition, Frame.position,
        ShapeTransport.indexAlong, Fin.cast] at coordinate ⊢
      omega
    · simp [Frame.shape, Frame.edgePadding, Frame.withPosition, ShapeTransport.indexAlong,
        Fin.cast, same] at coordinate ⊢
      omega
  · have invalid : ¬ (∀ axis, (ReductionWindow.boundedIndex? (frame.shape extent axis)
        (((ShapeTransport.indexAlong (edgePadding_shape frame low high) index axis).val : Int) -
          (frame.edgePadding low high).low axis)).isSome) := by
      intro valid
      exact inside ((edgePadding_inside_iff frame low high index).mp valid)
    rw [dite_eq_right invalid, dite_eq_right inside]

end TensorRewrite.Theory.Concatenation
