module

public import TensorRewrite.Theory.ConcatenationGraphs

/-! Shape-carrying congruence, common Slice factoring and selected-axis graph arithmetic. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Concatenation

open Pilot

/-- Complete extent-and-value equality identifies the typed operand blocks themselves. -/
theorem block_eq_of_values {rank : Nat} {frame : Frame rank} {α : Type}
    (left right : Block frame α) (same : left.extent = right.extent)
    (values : frame.castTensor same left.values = right.values) : left = right := by
  cases left with
  | mk leftExtent leftValues =>
    cases right with
    | mk rightExtent rightValues =>
      dsimp only at same values
      cases same
      rw [castTensor_refl] at values
      cases values
      rfl

/-- Packing a unary concatenation retains both the original extent and every original value. -/
theorem pack_unary {rank : Nat} {frame : Frame rank} {α : Type} (block : Block frame α) :
    pack [block] = block :=
  block_eq_of_values _ _ (by simp [pack, total]) (concatenate_unary block)

/-- Packed flattening preserves the complete shape-and-value object. -/
theorem pack_flatten {rank : Nat} {frame : Frame rank} {α : Type}
    (groups : List (List (Block frame α))) : pack (groups.map pack) = pack groups.flatten :=
  block_eq_of_values _ _ (total_flatten groups) (concatenate_flatten groups)

/-- A contiguous operand group can be treated as one actual inner concatenation in any context. -/
theorem pack_group_context {rank : Nat} {frame : Frame rank} {α : Type}
    (leading group trailing : List (Block frame α)) :
    pack (leading ++ (group ++ trailing)) = pack (leading ++ (pack group :: trailing)) := by
  have original := pack_flatten [leading, group, trailing]
  have grouped := pack_flatten [leading, [pack group], trailing]
  simp only [List.map_cons, List.map_nil, List.flatten_cons, List.flatten_nil,
    List.append_nil, List.singleton_append, pack_unary] at original grouped
  exact original.symm.trans grouped

/-- Extent transport and Concat read the original output position with the derived bound. -/
theorem cast_concatenate_value {rank outputExtent : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) (same : total blocks = outputExtent)
    (index : Index (frame.shape outputExtent)) :
    frame.castTensor same (concatenate blocks) index =
      readAt blocks (frame.rest index) (frame.position index).val (by
        rw [same]
        exact (frame.position index).isLt) := by
  let position : Fin (total blocks) := ⟨(frame.position index).val, by
    rw [same]
    exact (frame.position index).isLt⟩
  change readAt blocks (frame.rest (frame.withPosition index position))
      (frame.position (frame.withPosition index position)).val
      (frame.position (frame.withPosition index position)).isLt = _
  have restSame := rest_withPosition frame index position
  have positionSame := position_withPosition frame index position
  calc
    _ = readAt blocks (frame.rest index)
        (frame.position (frame.withPosition index position)).val
        (frame.position (frame.withPosition index position)).isLt :=
      congrArg (fun rest => readAt blocks rest
        (frame.position (frame.withPosition index position)).val
        (frame.position (frame.withPosition index position)).isLt) restSame
    _ = readAt blocks (frame.rest index) position.val position.isLt :=
      congrArg (fun point : Fin (total blocks) =>
        readAt blocks (frame.rest index) point.val point.isLt) positionSame

/-- The scalar Broadcast operand has the intended value at every declared tensor coordinate. -/
theorem constantBlock_values {rank : Nat} {frame : Frame rank} {α : Type}
    (extent : Nat) (value : α) : (constantBlock (frame := frame) extent value).values =
      Tensor.constant value := rfl

/-- Legal raw Slice bounds derive their nonnegative output count, without canonicalizing limits. -/
theorem axis_valid_inferred (extent : Nat) (axis : SliceShape.Axis)
    (start : 0 ≤ axis.start) (ordered : axis.start ≤ axis.limit)
    (bounded : axis.limit ≤ extent) (positive : 0 < axis.stride) :
    SliceShape.IsWellFormed extent axis.elementCount.toNat axis := by
  have countNonnegative : 0 ≤ axis.elementCount :=
    Int.tdiv_nonneg (by omega) (by omega)
  exact ⟨start, ordered, bounded, positive, by omega, (Int.toNat_of_nonneg countNonnegative).symm⟩

/-- Common positive stride and exact adjacency derive the merged Slice element count. -/
theorem merged_axis_count {extent firstLength secondLength : Nat}
    (first second : SliceShape.Axis)
    (firstValid : SliceShape.IsWellFormed extent firstLength first)
    (secondValid : SliceShape.IsWellFormed extent secondLength second)
    (sameStride : second.stride = first.stride)
    (adjacent : second.start = first.start + (firstLength : Int) * first.stride) :
    (mergeAxis first second).elementCount = (firstLength + secondLength : Nat) := by
  have positive := firstValid.2.2.2.1
  have ordered := secondValid.2.1
  have numerator : 0 ≤ second.limit - second.start + second.stride - 1 := by
    omega
  have mergedNumerator : (mergeAxis first second).limit - (mergeAxis first second).start +
      (mergeAxis first second).stride - 1 =
        (firstLength : Int) * first.stride + (second.limit - second.start + second.stride - 1) := by
    simp only [mergeAxis]
    rw [adjacent, sameStride]
    ring
  have mergedNonnegative : 0 ≤ (firstLength : Int) * first.stride +
      (second.limit - second.start + second.stride - 1) :=
    Int.add_nonneg (Int.mul_nonneg (by omega) (by omega)) numerator
  unfold SliceShape.Axis.elementCount
  rw [mergedNumerator]
  change ((firstLength : Int) * first.stride +
      (second.limit - second.start + second.stride - 1)).tdiv first.stride = _
  rw [Int.tdiv_eq_ediv_of_nonneg mergedNonnegative,
    Int.mul_add_ediv_right _ _ (by omega), ← sameStride,
    ← Int.tdiv_eq_ediv_of_nonneg numerator]
  change (firstLength : Int) + second.elementCount = (firstLength + secondLength : Nat)
  rw [secondValid.2.2.2.2.2]
  exact (Int.natCast_add _ _).symm

/-- Adjacency and common positive stride derive the merged Slice's entire well-formedness proof. -/
theorem merged_axis_valid {extent firstLength secondLength : Nat}
    (first second : SliceShape.Axis)
    (firstValid : SliceShape.IsWellFormed extent firstLength first)
    (secondValid : SliceShape.IsWellFormed extent secondLength second)
    (sameStride : second.stride = first.stride)
    (adjacent : second.start = first.start + (firstLength : Int) * first.stride) :
    SliceShape.IsWellFormed extent (firstLength + secondLength) (mergeAxis first second) := by
  have positive := firstValid.2.2.2.1
  have product : 0 ≤ (firstLength : Int) * first.stride :=
    Int.mul_nonneg (by omega) (by omega)
  have firstStart := firstValid.1
  have secondOrdered := secondValid.2.1
  have bounded := secondValid.2.2.1
  refine ⟨firstStart, ?_, bounded, positive, by omega,
    merged_axis_count first second firstValid secondValid sameStride adjacent⟩
  dsimp only [mergeAxis]
  omega

/-- The second source interval and the merged interval read the identical signed coordinate. -/
theorem adjacent_coordinate {firstLength : Nat} (first second : SliceShape.Axis)
    (sameStride : second.stride = first.stride)
    (adjacent : second.start = first.start + (firstLength : Int) * first.stride)
    (position : Nat) (after : firstLength ≤ position) :
    second.start + second.stride * (position - firstLength : Nat) =
      first.start + first.stride * (position : Int) := by
  have split : (firstLength : Int) + (position - firstLength : Nat) = position := by omega
  rw [sameStride, adjacent]
  calc
    _ = first.start + first.stride *
        ((firstLength : Int) + (position - firstLength : Nat)) := by ring
    _ = _ := by rw [split]

/-- The actual Pad attributes derive exactly the selected low/input/high output extent. -/
theorem edgePadding_shape {rank extent : Nat} (frame : Frame rank) (low high : Nat) :
    (frame.edgePadding low high).outputShape (frame.shape extent) =
      frame.shape (low + extent + high) := by
  funext axis
  by_cases same : axis = frame.axis <;>
    simp [Frame.edgePadding, SlicePad.Padding.outputShape, Frame.shape, same]

end TensorRewrite.Theory.Concatenation
