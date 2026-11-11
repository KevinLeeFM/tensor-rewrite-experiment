module

public import TensorRewrite.Theory.ConcatenationProof

/-! Legal unit-stride Slice graphs selecting actual contiguous concatenation operands. All
other dimensions are retained, and leading offsets and output extents are derived independently.
-/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Concatenation

open Pilot

/-- Crop a selected operand group after discarding the derived leading and trailing groups. -/
theorem slice_selected {rank : Nat} {frame : Frame rank} {α : Type}
    (leading selected trailing : List (Block frame α)) (start length : Nat)
    (fits : start + length ≤ total selected) :
    frame.slice (concatenate (leading ++ (selected ++ trailing))) (total leading + start) length
        (by rw [total_append, total_append]; omega) =
      frame.slice (concatenate selected) start length fits := by
  funext index
  simp only [Frame.slice, concatenate, rest_withPosition, position_withPosition]
  have before : start + (frame.position index).val < total selected := by
    have bound := (frame.position index).isLt
    omega
  simpa only [Nat.add_assoc] using readAt_middle leading selected trailing (frame.rest index)
    (start + (frame.position index).val) before (by
      rw [total_append, total_append]
      omega)

/-- Slice of a unary concatenation is the same legal Slice of the actual operand. -/
theorem slice_unary {rank : Nat} {frame : Frame rank} {α : Type}
    (block : Block frame α) (start length : Nat) (fits : start + length ≤ block.extent) :
    frame.slice (concatenate [block]) start length (by simpa [total] using fits) =
      frame.slice block.values start length fits := by
  have transported := slice_castTensor (by simp [total]) (concatenate [block]) start length
    (by simpa [total] using fits) fits
  rw [concatenate_unary] at transported
  exact transported.symm

/-- A contained subrange of one operand uses the actual leading-adjusted Slice attributes. -/
theorem slice_single_piece {rank : Nat} {frame : Frame rank} {α : Type}
    (leading trailing : List (Block frame α)) (block : Block frame α) (start length : Nat)
    (fits : start + length ≤ block.extent) :
    frame.slice (concatenate (leading ++ (block :: trailing))) (total leading + start) length
        (by rw [total_append]; simp only [total]; omega) =
      frame.slice block.values start length fits := by
  exact (slice_selected leading [block] trailing start length (by simpa [total] using fits)).trans
    (slice_unary block start length fits)

/-- An exact operand interval recovers that operand with its entire original tensor shape. -/
theorem slice_exact_piece {rank : Nat} {frame : Frame rank} {α : Type}
    (leading trailing : List (Block frame α)) (block : Block frame α) :
    frame.slice (concatenate (leading ++ (block :: trailing))) (total leading) block.extent
        (by rw [total_append]; simp only [total]; omega) = block.values := by
  have exactSlice := slice_single_piece leading trailing block 0 block.extent (by omega)
  simpa only [Nat.add_zero, slice_full] using exactSlice

end TensorRewrite.Theory.Concatenation
