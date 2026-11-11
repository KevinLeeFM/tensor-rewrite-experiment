module

public import TensorRewrite.Theory.ConcatenationSlice

/-! Shape and coordinate diagnostics for independently stated concatenation profiles. These
do not establish that an external compiler admits the corresponding mutations.
-/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Concatenation

open Pilot

/-- A zero non-concatenated dimension makes every positive-length operand empty. -/
def emptyOtherFrame : Frame 2 := ⟨fun _ => 0, 0⟩

/-- Two empty operands retain different positive selected-axis extents. -/
def emptyOtherBlocks : List (Block emptyOtherFrame Nat) :=
  [⟨2, Tensor.constant 7⟩, ⟨3, Tensor.constant 9⟩]

/-- All-empty values alone do not make the first operand's shape equal the output shape. -/
theorem empty_first_shape_refuted :
    (∀ block ∈ emptyOtherBlocks, block.hasElements = false) ∧
      emptyOtherFrame.shape (total emptyOtherBlocks) 0 ≠ emptyOtherFrame.shape 2 0 := by
  decide

/-- Unconditionally filtering actual empty tensors can change the derived output shape. -/
theorem empty_filter_shape_refuted :
    emptyOtherFrame.shape (total (filterEmpty emptyOtherBlocks)) 0 ≠
      emptyOtherFrame.shape (total emptyOtherBlocks) 0 := by decide

/-- A one-dimensional frame for concrete order and offset diagnostics. -/
def lineFrame : Frame 1 := ⟨fun _ => 1, 0⟩

/-- Insert an actual selected coordinate into the one-dimensional frame. -/
def lineIndex {extent : Nat} (position : Fin extent) : Index (lineFrame.shape extent) :=
  lineFrame.withPosition (inputExtent := 1)
    (fun _ => ⟨0, by dsimp [lineFrame, Frame.shape]; split <;> decide⟩) position

/-- Reordering concatenation operands changes the first output value. -/
theorem operand_order_refuted :
    concatenate ([⟨1, Tensor.constant 7⟩, ⟨1, Tensor.constant 9⟩] : List (Block lineFrame Nat))
        (lineIndex (0 : Fin 2)) ≠
      concatenate [⟨1, Tensor.constant 9⟩, ⟨1, Tensor.constant 7⟩]
        (lineIndex (0 : Fin 2)) := by decide

/-- Removing a leading operand without adjusting the Slice start reads the wrong operand. -/
theorem slice_offset_refuted :
    let first : Block lineFrame Nat := ⟨2, Tensor.constant 7⟩
    let second : Block lineFrame Nat := ⟨2, Tensor.constant 9⟩
    lineFrame.slice (concatenate [first, second]) 0 2 (by decide) (lineIndex (0 : Fin 2)) ≠
      second.values (lineIndex (0 : Fin 2)) := by decide

end TensorRewrite.Theory.Concatenation
