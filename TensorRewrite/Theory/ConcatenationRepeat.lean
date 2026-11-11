module

public import TensorRewrite.Theory.ConcatenationGraphLemmas
public import TensorRewrite.Theory.UnitAxisTargetLemmas

/-! Repeated unit-axis operands become ordinary rank-deleting Reshape followed by Broadcast. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Concatenation

open Pilot

/-- Repeating a unit selected extent derives the exact copy-count output dimension. -/
theorem total_replicate_unit {rank : Nat} {frame : Frame rank} {α : Type}
    (input : Tensor (frame.shape 1) α) (copies : Nat) :
    total (List.replicate copies (⟨1, input⟩ : Block frame α)) = copies := by
  induction copies with
  | zero => rfl
  | succ copies ih => simp [List.replicate_succ, total, ih, Nat.add_comm]

/-- Repeated operands read the same rest coordinate; zero copies need no default data. -/
theorem readAt_replicate_unit {rank : Nat} {frame : Frame rank} {α : Type}
    (input : Tensor (frame.shape 1) α) (copies : Nat) (rest : Index (frame.shape 1))
    (position : Nat)
    (bound : position < total (List.replicate copies (⟨1, input⟩ : Block frame α))) :
    readAt (List.replicate copies (⟨1, input⟩ : Block frame α)) rest position bound =
      input rest := by
  induction copies generalizing position with
  | zero => simp [total] at bound
  | succ copies ih =>
    simp only [List.replicate_succ, readAt]
    by_cases before : position < 1
    · rw [dite_eq_left before]
      have zero : (⟨position, before⟩ : Fin 1) = 0 := by apply Fin.ext; omega
      rw [zero, withPosition_zero]
    · rw [dite_eq_right before]
      exact ih _ _

/-- Construct the actual delete-axis Reshape and signed-axis Broadcast for any legal frame. -/
def repeatTarget {rank : Nat} {α : Type} (frame : Frame (rank + 1)) (copies : Nat)
    (input : Tensor (frame.shape 1) α) : Tensor (frame.shape copies) α :=
  let plan := UnitAxis.ofAxis frame.extents frame.axis
  let original := ShapeTransport.tensorAlong
    (UnitAxis.input_ofAxis frame.extents frame.axis).symm input
  ShapeTransport.tensorAlong (UnitAxis.target_ofAxis frame.extents frame.axis copies)
    (UnitAxis.sequence plan copies original)

/-- The actual target operators retain every nonselected coordinate and insert only unit zero. -/
theorem repeatTarget_value {rank : Nat} {α : Type} (frame : Frame (rank + 1)) (copies : Nat)
    (input : Tensor (frame.shape 1) α) (index : Index (frame.shape copies)) :
    repeatTarget frame copies input index = input (frame.rest index) := by
  unfold repeatTarget ShapeTransport.tensorAlong
  rw [UnitAxis.sequence_value]
  apply congrArg input
  funext axis
  apply Fin.ext
  change ((UnitAxis.ofAxis frame.extents frame.axis).insertIndex
    ((UnitAxis.ofAxis frame.extents frame.axis).projectIndex
      (ShapeTransport.indexAlong (UnitAxis.target_ofAxis frame.extents frame.axis copies) index))
        axis).val = (frame.rest index axis).val
  rw [UnitAxis.sourceIndex_value, UnitAxis.axis_ofAxis]
  by_cases same : axis = frame.axis <;>
    simp [Frame.rest, Frame.withPosition, ShapeTransport.indexAlong, Fin.cast, same]

/-- Repeated unit-axis concatenation equals the ordinary Reshape/Broadcast target at every rank. -/
theorem concatenate_repeated {rank : Nat} {α : Type} (frame : Frame (rank + 1)) (copies : Nat)
    (input : Tensor (frame.shape 1) α) :
    frame.castTensor (total_replicate_unit input copies)
        (concatenate (List.replicate copies (⟨1, input⟩ : Block frame α))) =
      repeatTarget frame copies input := by
  funext index
  simp only [Frame.castTensor, concatenate, rest_withPosition, position_withPosition]
  exact (readAt_replicate_unit input copies (frame.rest index) (frame.position index).val _).trans
    (repeatTarget_value frame copies input index).symm

end TensorRewrite.Theory.Concatenation
