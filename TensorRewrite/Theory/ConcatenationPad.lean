module

public import TensorRewrite.Theory.ConcatenationPadLemmas

/-! Scalar Broadcast concatenation equals the existing independently specified Pad operator. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Concatenation

open Pilot

/-- A leading scalar Broadcast operand becomes actual low-edge Pad with the same fill. -/
theorem concatenate_pad_low {rank extent : Nat} {α : Type} (frame : Frame rank)
    (low : Nat) (fill : α) (input : Tensor (frame.shape extent) α) :
    frame.castTensor (by simp [total, constantBlock])
        (concatenate [constantBlock low fill, (⟨extent, input⟩ : Block frame α)]) =
      ShapeTransport.tensorAlong (edgePadding_shape frame low 0)
        ((frame.edgePadding low 0).tensor fill input) := by
  funext index
  rw [cast_concatenate_value, edgePadding_value]
  by_cases before : (frame.position index).val < low
  · have beforeBlock : (frame.position index).val <
        (constantBlock (frame := frame) low fill).extent := before
    rw [readAt, dite_eq_left beforeBlock, dite_eq_right (by omega)]
    rfl
  · have bound := (frame.position index).isLt
    have inside : low ≤ (frame.position index).val ∧
        (frame.position index).val < low + extent := by omega
    have tailBound : (frame.position index).val - low < extent := by omega
    have afterBlock : ¬ (frame.position index).val <
        (constantBlock (frame := frame) low fill).extent := before
    have tailBlock : (frame.position index).val -
        (constantBlock (frame := frame) low fill).extent < extent := tailBound
    rw [readAt, dite_eq_right afterBlock, readAt, dite_eq_left tailBlock, dite_eq_left inside]
    simp only [Frame.rest, withPosition_withPosition]
    rfl

/-- A trailing scalar Broadcast operand becomes actual high-edge Pad with the same fill. -/
theorem concatenate_pad_high {rank extent : Nat} {α : Type} (frame : Frame rank)
    (high : Nat) (fill : α) (input : Tensor (frame.shape extent) α) :
    frame.castTensor (by simp [total, constantBlock])
        (concatenate [(⟨extent, input⟩ : Block frame α), constantBlock high fill]) =
      ShapeTransport.tensorAlong (edgePadding_shape frame 0 high)
        ((frame.edgePadding 0 high).tensor fill input) := by
  funext index
  rw [cast_concatenate_value, edgePadding_value]
  by_cases before : (frame.position index).val < extent
  · have inside : 0 ≤ (frame.position index).val ∧
        (frame.position index).val < 0 + extent := by omega
    rw [readAt, dite_eq_left before, dite_eq_left inside]
    simp only [Frame.rest, withPosition_withPosition, Nat.sub_zero]
  · have bound := (frame.position index).isLt
    have outside : ¬ (0 ≤ (frame.position index).val ∧
        (frame.position index).val < 0 + extent) := by omega
    have tailBound : (frame.position index).val - extent < high := by omega
    have tailBlock : (frame.position index).val - extent <
        (constantBlock (frame := frame) high fill).extent := tailBound
    rw [readAt, dite_eq_right before, readAt, dite_eq_left tailBlock, dite_eq_right outside]
    rfl

end TensorRewrite.Theory.Concatenation
