module

public import TensorRewrite.Theory.ConcatenationAdjacent
public import TensorRewrite.Theory.ConcatenationPad

/-! Paper-era Concat and selected Slice graphs, including their complete shapes. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Concatenate

open Pilot Theory.Concatenation Theory

/-- The paper's binary Concat, represented as a shape-carrying tensor block. -/
def pair {rank : Nat} {frame : Frame rank} {α : Type}
    (left right : Block frame α) : Block frame α := pack [left, right]

/-- The paper's nonempty list Concat recursively joins its first block to the tail. -/
def listConcat {rank : Nat} {frame : Frame rank} {α : Type}
    (first : Block frame α) : List (Block frame α) → Block frame α
  | [] => first
  | second :: rest => pair first (listConcat second rest)

/-- `concat/rule01`: the two-element list unfolds to one binary Concat. -/
theorem list_pair {rank : Nat} {frame : Frame rank} {α : Type}
    (left right : Block frame α) : listConcat left [right] = pair left right := rfl

/-- `concat/rule02`: changing binary grouping preserves the shape and values. -/
theorem associate {rank : Nat} {frame : Frame rank} {α : Type}
    (first second third : Block frame α) :
    pair first (pair second third) = pair (pair first second) third := by
  have rightGrouped := pack_group_context [first] [second, third] []
  have leftGrouped := pack_group_context [] [first, second] [third]
  simpa [pair] using rightGrouped.symm.trans leftGrouped

/-- `concat/rule03`: the three-element list unfolds to the right-grouped graph. -/
theorem list_three {rank : Nat} {frame : Frame rank} {α : Type}
    (first second third : Block frame α) :
    listConcat first [second, third] = pair first (pair second third) := rfl

/-- `concat/rule07`: the right-grouped graph equals list concatenation. -/
theorem list_three_reverse {rank : Nat} {frame : Frame rank} {α : Type}
    (first second third : Block frame α) :
    pair first (pair second third) = listConcat first [second, third] := rfl

/-- The recursive list graph is equal to independently defined flat tensor concatenation. -/
theorem list_three_flat {rank : Nat} {frame : Frame rank} {α : Type}
    (first second third : Block frame α) :
    listConcat first [second, third] = pack [first, second, third] := by
  simpa [listConcat, pair] using (pack_group_context [first] [second, third] []).symm

/-- For a legal unit-stride Slice, its declared length is exactly limit minus start. -/
theorem unit_stride_adjacent {extent length : Nat} (first second : SliceShape.Axis)
    (valid : SliceShape.IsWellFormed extent length first) (unitStride : first.stride = 1)
    (touching : second.start = first.limit) :
    second.start = first.start + (length : Int) * first.stride := by
  have count := valid.2.2.2.2.2
  simp [SliceShape.Axis.elementCount, unitStride] at count
  rw [touching, unitStride]
  omega

/-- `concat/rule04`: legal touching unit-stride Slices merge, on all actual tensor values. -/
theorem touching_slices {rank extent firstLength secondLength : Nat}
    {inputFrame : Frame rank} {α : Type} (crop : Crop inputFrame)
    (input : Tensor (inputFrame.shape extent) α) (first second : SliceShape.Axis)
    (firstValid : SliceShape.IsWellFormed extent firstLength first)
    (secondValid : SliceShape.IsWellFormed extent secondLength second)
    (firstUnit : first.stride = 1) (secondUnit : second.stride = 1)
    (touching : second.start = first.limit) :
    pack [crop.blockWith input first firstLength firstValid,
        crop.blockWith input second secondLength secondValid] =
      crop.blockWith input (mergeAxis first second) (firstLength + secondLength)
        (merged_axis_valid first second firstValid secondValid (secondUnit.trans firstUnit.symm)
          (unit_stride_adjacent first second firstValid firstUnit touching)) :=
  adjacent_slices_pair crop input first second firstValid secondValid
    (secondUnit.trans firstUnit.symm)
    (unit_stride_adjacent first second firstValid firstUnit touching)

/-- `concat/rule05`: a leading uniform block becomes low-edge Pad. -/
theorem pad_low {rank extent : Nat} {α : Type} (frame : Frame rank)
    (low : Nat) (fill : α) (input : Tensor (frame.shape extent) α) :
    frame.castTensor (by simp [total, constantBlock])
        (concatenate [constantBlock low fill, (⟨extent, input⟩ : Block frame α)]) =
      ShapeTransport.tensorAlong (edgePadding_shape frame low 0)
        ((frame.edgePadding low 0).tensor fill input) := concatenate_pad_low frame low fill input

/-- `concat/rule06`: a trailing uniform block becomes high-edge Pad. -/
theorem pad_high {rank extent : Nat} {α : Type} (frame : Frame rank)
    (high : Nat) (fill : α) (input : Tensor (frame.shape extent) α) :
    frame.castTensor (by simp [total, constantBlock])
        (concatenate [(⟨extent, input⟩ : Block frame α), constantBlock high fill]) =
      ShapeTransport.tensorAlong (edgePadding_shape frame 0 high)
        ((frame.edgePadding 0 high).tensor fill input) := concatenate_pad_high frame high fill input

/-- `slice/rule08`: a full Slice of the second segment recovers its complete shape and data. -/
theorem slice_second {rank : Nat} {frame : Frame rank} {α : Type}
    (first second : Block frame α) :
    frame.slice (concatenate [first, second]) first.extent second.extent
        (by simp [total]) = second.values := by
  simpa only [List.cons_append, List.nil_append, List.append_nil, total, Nat.add_zero] using
    slice_exact_piece [first] [] second

/-- Unit-stride paper start and limit infer an interval fitting within the first operand. -/
theorem paper_interval {extent length : Nat} (axis : SliceShape.Axis)
    (valid : SliceShape.IsWellFormed extent length axis) (unit : axis.stride = 1) :
    axis.start + (length : Int) = axis.limit ∧ axis.start + length ≤ extent := by
  have count := valid.2.2.2.2.2
  simp [SliceShape.Axis.elementCount, unit] at count
  have limit := valid.2.2.1
  omega

/-- A start beyond the first operand is exactly its extent plus the paper's shifted start. -/
theorem paper_offset (extent start limit length : Nat) (after : extent ≤ start)
    (endAt : start + length = limit) :
    start = extent + (start - extent) ∧ limit - extent = (start - extent) + length := by
  omega

/-- `slice/rule10`: a unit-stride interval inside the first concatenated operand. -/
theorem slice_first_piece {rank : Nat} {frame : Frame rank} {α : Type}
    (first second : Block frame α) (start length : Nat) (fits : start + length ≤ first.extent) :
    frame.slice (concatenate [first, second]) (0 + start) length (by simp [total]; omega) =
      frame.slice first.values start length fits := by
  simpa only [List.nil_append, total] using
    slice_single_piece [] [second] first start length fits

/-- `slice/rule11`: subtracting the first extent selects the matching second interval. -/
theorem slice_second_piece {rank : Nat} {frame : Frame rank} {α : Type}
    (first second : Block frame α) (start length : Nat) (fits : start + length ≤ second.extent) :
    frame.slice (concatenate [first, second]) (first.extent + start) length
        (by simp [total]; omega) = frame.slice second.values start length fits := by
  simpa only [List.cons_append, List.nil_append, total, Nat.add_zero] using
    slice_single_piece [first] [] second start length fits

#print axioms paper_offset
#print axioms paper_interval
#print axioms slice_first_piece
#print axioms slice_second_piece
#print axioms list_pair
#print axioms associate
#print axioms list_three
#print axioms list_three_reverse
#print axioms touching_slices
#print axioms pad_low
#print axioms pad_high
#print axioms slice_second

end TensorRewrite.PaperComparison.Concatenate
