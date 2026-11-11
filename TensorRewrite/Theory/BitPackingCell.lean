module

public import TensorRewrite.Theory.BitPackingProof

/-! Same-cell bitcast graphs retain the existing independently defined dense-layout maps. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BitPacking

open Pilot

/-- Identical dense storage views preserve every logical cell value. -/
theorem cell_bitcast_refl {rank : Nat} {shape : Shape rank} {α : Type}
    (layout : DenseLayout rank) (input : Tensor shape α) :
    DenseLayout.bitcastTensor layout layout shape rfl input = input :=
  DenseLayout.read_write layout input

/-- Composing independent dense cell bitcasts cancels the intermediate storage view. -/
theorem cell_bitcast_compose {firstRank middleRank lastRank : Nat} {α : Type}
    {firstShape : Shape firstRank} (middleShape : Shape middleRank) (lastShape : Shape lastRank)
    (firstLayout : DenseLayout firstRank) (middleLayout : DenseLayout middleRank)
    (lastLayout : DenseLayout lastRank)
    (left : LinearIndex.elementCount (firstLayout.orderedShape firstShape) =
      LinearIndex.elementCount (middleLayout.orderedShape middleShape))
    (right : LinearIndex.elementCount (middleLayout.orderedShape middleShape) =
      LinearIndex.elementCount (lastLayout.orderedShape lastShape)) (input : Tensor firstShape α) :
    DenseLayout.bitcastTensor middleLayout lastLayout lastShape right
        (DenseLayout.bitcastTensor firstLayout middleLayout middleShape left input) =
      DenseLayout.bitcastTensor firstLayout lastLayout lastShape (left.trans right) input := by
  change lastLayout.read (fun lastCell =>
    middleLayout.write (middleLayout.read (fun middleCell =>
      firstLayout.write input (Fin.cast left.symm middleCell))) (Fin.cast right.symm lastCell)) =
    lastLayout.read (fun lastCell =>
      firstLayout.write input (Fin.cast (left.trans right).symm lastCell))
  rw [DenseLayout.write_read]
  rfl

/-- Any pure elementwise scalar map commutes with a same-cell physical reindexing. -/
theorem cell_bitcast_map {inputRank outputRank : Nat} {α β : Type}
    {inputShape : Shape inputRank} (inputLayout : DenseLayout inputRank)
    (outputLayout : DenseLayout outputRank) (outputShape : Shape outputRank)
    (same : LinearIndex.elementCount (inputLayout.orderedShape inputShape) =
      LinearIndex.elementCount (outputLayout.orderedShape outputShape))
    (function : α → β) (input : Tensor inputShape α) :
    DenseLayout.bitcastTensor inputLayout outputLayout outputShape same
        (Tensor.map function input) =
      Tensor.map function
        (DenseLayout.bitcastTensor inputLayout outputLayout outputShape same input) := rfl

/-- A pure Unary operation inside a dense Bitcast sandwich moves before the composed Bitcast. -/
theorem cell_bitcast_sandwich {firstRank middleRank lastRank : Nat} {α β : Type}
    {firstShape : Shape firstRank} (middleShape : Shape middleRank) (lastShape : Shape lastRank)
    (firstLayout : DenseLayout firstRank) (middleLayout : DenseLayout middleRank)
    (lastLayout : DenseLayout lastRank)
    (left : LinearIndex.elementCount (firstLayout.orderedShape firstShape) =
      LinearIndex.elementCount (middleLayout.orderedShape middleShape))
    (right : LinearIndex.elementCount (middleLayout.orderedShape middleShape) =
      LinearIndex.elementCount (lastLayout.orderedShape lastShape))
    (function : α → β) (input : Tensor firstShape α) :
    DenseLayout.bitcastTensor middleLayout lastLayout lastShape right
        (Tensor.map function
          (DenseLayout.bitcastTensor firstLayout middleLayout middleShape left input)) =
      DenseLayout.bitcastTensor firstLayout lastLayout lastShape (left.trans right)
        (Tensor.map function input) := by
  rw [← cell_bitcast_map firstLayout middleLayout middleShape left,
    cell_bitcast_compose]

end TensorRewrite.Theory.BitPacking
