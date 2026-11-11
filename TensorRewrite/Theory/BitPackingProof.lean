module

public import TensorRewrite.Theory.BitPackingLemmas

/-! Composition, identity and ordinary dense-cell bitcast bridges for exact word repacking. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BitPacking

open Pilot

/-- Repacking to identical cell/width/order parameters retains every stored word. -/
theorem repack_refl {cells width : Nat} (order : Order) (input : Words cells width) :
    repack order order rfl input = input := inflate_flatten order input

/-- Intermediate word widths, cell counts and bit orders cancel through the actual bit stream. -/
theorem repack_compose {firstCells firstWidth middleCells middleWidth lastCells lastWidth : Nat}
    (firstOrder middleOrder lastOrder : Order)
    (left : firstCells * firstWidth = middleCells * middleWidth)
    (right : middleCells * middleWidth = lastCells * lastWidth)
    (input : Words firstCells firstWidth) :
    repack middleOrder lastOrder right (repack firstOrder middleOrder left input) =
      repack firstOrder lastOrder (left.trans right) input := by
  unfold repack
  rw [flatten_inflate, transport_trans]

/-- Same-width repacking is exactly bounded physical-cell reindexing. -/
theorem repack_same_width {inputCells outputCells width : Nat} (order : Order)
    (same : inputCells = outputCells) (input : Words inputCells width) :
    repack order order (congrArg (fun cells => cells * width) same) input =
      fun cell => input (Fin.cast same.symm cell) := by
  cases same
  exact repack_refl order input

/-- Logical word reinterpretation with identical shape, width and order is the identity. -/
theorem logical_convert_refl {rank width : Nat} {shape : Shape rank}
    (order : Order) (input : Tensor shape (BitVec width)) :
    logicalConvert shape order order rfl input = input := by
  funext index
  simp only [logicalConvert, repack_refl, LinearIndex.delinearize_linearize]

/-- Actual rank-changing logical word reinterpretations compose through every intermediate shape. -/
theorem logical_convert_compose
    {firstRank middleRank lastRank firstWidth middleWidth lastWidth : Nat}
    {firstShape : Shape firstRank} (middleShape : Shape middleRank) (lastShape : Shape lastRank)
    (firstOrder middleOrder lastOrder : Order)
    (left : LinearIndex.elementCount firstShape * firstWidth =
      LinearIndex.elementCount middleShape * middleWidth)
    (right : LinearIndex.elementCount middleShape * middleWidth =
      LinearIndex.elementCount lastShape * lastWidth)
    (input : Tensor firstShape (BitVec firstWidth)) :
    logicalConvert lastShape middleOrder lastOrder right
        (logicalConvert middleShape firstOrder middleOrder left input) =
      logicalConvert lastShape firstOrder lastOrder (left.trans right) input := by
  funext index
  simp only [logicalConvert, LinearIndex.linearize_delinearize]
  rw [repack_compose]

/-- Dense-layout word reinterpretation with identical storage parameters is the identity. -/
theorem physical_convert_refl {rank width : Nat} {shape : Shape rank}
    (layout : DenseLayout rank) (order : Order) (input : Tensor shape (BitVec width)) :
    physicalConvert layout layout shape order order rfl input = input := by
  unfold physicalConvert
  rw [repack_refl, DenseLayout.read_write]

/-- Arbitrary legal dense intermediate layouts cancel after actual encode/read round trips. -/
theorem physical_convert_compose
    {firstRank middleRank lastRank firstWidth middleWidth lastWidth : Nat}
    {firstShape : Shape firstRank} (middleShape : Shape middleRank) (lastShape : Shape lastRank)
    (firstLayout : DenseLayout firstRank) (middleLayout : DenseLayout middleRank)
    (lastLayout : DenseLayout lastRank) (firstOrder middleOrder lastOrder : Order)
    (left : LinearIndex.elementCount (firstLayout.orderedShape firstShape) * firstWidth =
      LinearIndex.elementCount (middleLayout.orderedShape middleShape) * middleWidth)
    (right : LinearIndex.elementCount (middleLayout.orderedShape middleShape) * middleWidth =
      LinearIndex.elementCount (lastLayout.orderedShape lastShape) * lastWidth)
    (input : Tensor firstShape (BitVec firstWidth)) :
    physicalConvert middleLayout lastLayout lastShape middleOrder lastOrder right
        (physicalConvert firstLayout middleLayout middleShape firstOrder middleOrder left input) =
      physicalConvert firstLayout lastLayout lastShape firstOrder lastOrder
        (left.trans right) input := by
  unfold physicalConvert
  rw [DenseLayout.write_read, repack_compose]

/-- Same-width reinterpretation equals the independently defined dense cell Bitcast. -/
theorem physical_convert_same_width {inputRank outputRank width : Nat}
    {inputShape : Shape inputRank} (inputLayout : DenseLayout inputRank)
    (outputLayout : DenseLayout outputRank) (outputShape : Shape outputRank) (order : Order)
    (same : LinearIndex.elementCount (inputLayout.orderedShape inputShape) =
      LinearIndex.elementCount (outputLayout.orderedShape outputShape))
    (input : Tensor inputShape (BitVec width)) :
    physicalConvert inputLayout outputLayout outputShape order order
        (congrArg (fun cells => cells * width) same) input =
      DenseLayout.bitcastTensor inputLayout outputLayout outputShape same input := by
  unfold physicalConvert
  rw [repack_same_width order same]
  rfl

end TensorRewrite.Theory.BitPacking
