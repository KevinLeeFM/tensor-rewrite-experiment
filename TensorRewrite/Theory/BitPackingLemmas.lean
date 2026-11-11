module

public import TensorRewrite.Theory.BitPacking

/-! Round trips for actual stored-word packing; no data-equality premise is assumed. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BitPacking

open Pilot

/-- Either declared bit order is its own inverse. -/
theorem bitIndex_involution {width : Nat} (order : Order) (bit : Fin width) :
    order.bitIndex (order.bitIndex bit) = bit := by
  cases order <;> simp [Order.bitIndex]

/-- The actual BitVec constructor reads exactly its independently supplied bounded bit. -/
theorem wordOfBits_getLsb {width : Nat} (bits : Fin width → Bool) (bit : Fin width) :
    (wordOfBits bits).getLsb bit = bits bit := by
  simp [wordOfBits, BitVec.getLsb_eq_getElem, ← BitVec.getLsbD_eq_getElem,
    List.getD_eq_getElem?_getD, bit.isLt]

/-- Actual words are fully determined by their bounded least-significant-bit observations. -/
theorem word_ext {width : Nat} {left right : BitVec width}
    (same : ∀ bit : Fin width, left.getLsb bit = right.getLsb bit) : left = right := by
  apply BitVec.eq_of_getLsbD_eq
  intro bit bounded
  simpa [BitVec.getLsb_eq_getElem, BitVec.getLsbD_eq_getElem bounded] using same ⟨bit, bounded⟩

/-- Flattening reconstructed words retains every original bit position. -/
theorem flatten_inflate {cells width : Nat} (order : Order) (bits : Bits (cells * width)) :
    flatten order (inflate order bits) = bits := by
  funext bit
  simp only [flatten, inflate, wordOfBits_getLsb, bitIndex_involution,
    FiniteProduct.join_row_column]

/-- Reconstructing actual words from their bit stream retains every word. -/
theorem inflate_flatten {cells width : Nat} (order : Order) (words : Words cells width) :
    inflate order (flatten order words) = words := by
  funext cell
  apply word_ext
  intro bit
  simp only [inflate, wordOfBits_getLsb, flatten, FiniteProduct.row_join,
    FiniteProduct.column_join, bitIndex_involution]

/-- Reflexive stream-size transport has no effect on any bit. -/
theorem transport_refl {size : Nat} (bits : Bits size) : transport rfl bits = bits := rfl

/-- Two equal-size transports retain exactly the original bit position. -/
theorem transport_trans {first middle last : Nat} (left : first = middle) (right : middle = last)
    (bits : Bits first) :
    transport right (transport left bits) = transport (left.trans right) bits :=
  rfl

/-- The flattened output of actual repacking is exactly the original physical bit stream. -/
theorem flatten_repack {inputCells inputWidth outputCells outputWidth : Nat}
    (inputOrder outputOrder : Order) (same : inputCells * inputWidth = outputCells * outputWidth)
    (input : Words inputCells inputWidth) :
    flatten outputOrder (repack inputOrder outputOrder same input) =
      transport same (flatten inputOrder input) :=
  flatten_inflate outputOrder _

/-- Appending a ratio derives the element count, including scalars and empty shapes. -/
theorem count_appendAxis {rank : Nat} (shape : Shape rank) (extent : Nat) :
    LinearIndex.elementCount (appendAxis shape extent) =
      LinearIndex.elementCount shape * extent := by
  induction rank with
  | zero => simp [appendAxis, LinearIndex.elementCount]
  | succ rank ih =>
    change shape 0 * LinearIndex.elementCount (appendAxis (fun axis => shape axis.succ) extent) = _
    rw [ih]
    exact (Nat.mul_assoc _ _ _).symm

/-- The rank-changing split shape derives total-bit preservation from its width ratio. -/
theorem split_bit_count {rank : Nat} (shape : Shape rank) (factor width : Nat) :
    LinearIndex.elementCount shape * (factor * width) =
      LinearIndex.elementCount (appendAxis shape factor) * width := by
  rw [count_appendAxis, Nat.mul_assoc]

/-- Standard dim0-major layout preserves the complete logical shape order. -/
theorem rowMajor_orderedShape {rank : Nat} (shape : Shape rank) :
    (DenseLayout.rowMajor rank).orderedShape shape = shape := by
  funext axis
  simp [DenseLayout.orderedShape, DenseLayout.rowMajor]

/-- Actual standard dense layouts derive the full storage-bit count of the split shape. -/
theorem physical_split_bit_count {rank : Nat} (shape : Shape rank) (factor width : Nat) :
    LinearIndex.elementCount ((DenseLayout.rowMajor rank).orderedShape shape) * (factor * width) =
      LinearIndex.elementCount
        ((DenseLayout.rowMajor (rank + 1)).orderedShape (appendAxis shape factor)) * width := by
  rw [rowMajor_orderedShape, rowMajor_orderedShape]
  exact split_bit_count shape factor width

/-- Equal storage-bit counts and at least one cell determine equal element widths. -/
theorem width_eq_of_nonempty {cells firstWidth secondWidth : Nat} (nonempty : 0 < cells)
    (same : cells * firstWidth = cells * secondWidth) : firstWidth = secondWidth :=
  Nat.eq_of_mul_eq_mul_left nonempty same

end TensorRewrite.Theory.BitPacking
