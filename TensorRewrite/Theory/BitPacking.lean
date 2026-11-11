module

public import TensorRewrite.Pilot.FiniteProductLemmas
public import TensorRewrite.Pilot.DenseLayoutLemmas

/-! Exact bounded bit streams for repacking stored words. Numerical conversion, tiled/padded
storage, aliasing and execution effects are separate contracts. Bit order is explicit.
-/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BitPacking

open Pilot

/-- The order of bits within each stored word, independent of the tensor's cell layout. -/
inductive Order where
  /-- The least significant bit is first in the physical stream. -/
  | leastFirst
  /-- The most significant bit is first in the physical stream. -/
  | mostFirst
  deriving DecidableEq, Repr

/-- Translate a stream offset within a word into its actual least-significant-bit index. -/
def Order.bitIndex {width : Nat} (order : Order) (bit : Fin width) : Fin width :=
  match order with
  | .leastFirst => bit
  | .mostFirst => bit.rev

/-- Stored words indexed by their actual bounded physical cell positions. -/
abbrev Words (cells width : Nat) := Fin cells → BitVec width

/-- Every physical bit has a bounded position; empty storage has no positions. -/
abbrev Bits (size : Nat) := Fin size → Bool

/-- Build an actual BitVec from independently supplied least-significant-indexed bits. -/
def wordOfBits {width : Nat} (bits : Fin width → Bool) : BitVec width :=
  (BitVec.ofBoolListLE (List.ofFn bits)).cast (by simp)

/-- Flatten actual words in cell order and the indicated within-word bit order. -/
def flatten {cells width : Nat} (order : Order) (words : Words cells width) :
    Bits (cells * width) :=
  fun bit => (words (FiniteProduct.row bit)).getLsb
    (order.bitIndex (FiniteProduct.column bit))

/-- Construct each actual output word by reading its independently bounded bit positions. -/
def inflate {cells width : Nat} (order : Order) (bits : Bits (cells * width)) : Words cells width :=
  fun cell => wordOfBits (fun bit => bits (FiniteProduct.join cell (order.bitIndex bit)))

/-- Transport only the type of an equal-size stream, preserving every physical bit position. -/
def transport {inputSize outputSize : Nat} (same : inputSize = outputSize)
    (bits : Bits inputSize) : Bits outputSize := fun bit => bits (Fin.cast same.symm bit)

/-- Repack equal total bits into the requested output cell count and word width. -/
def repack {inputCells inputWidth outputCells outputWidth : Nat}
    (inputOrder outputOrder : Order) (same : inputCells * inputWidth = outputCells * outputWidth)
    (input : Words inputCells inputWidth) : Words outputCells outputWidth :=
  inflate outputOrder (transport same (flatten inputOrder input))

/-- Reinterpret logical row-major tensor words through their complete flattened bit stream. -/
def logicalConvert {inputRank outputRank inputWidth outputWidth : Nat}
    {inputShape : Shape inputRank} (outputShape : Shape outputRank)
    (inputOrder outputOrder : Order)
    (same : LinearIndex.elementCount inputShape * inputWidth =
      LinearIndex.elementCount outputShape * outputWidth)
    (input : Tensor inputShape (BitVec inputWidth)) : Tensor outputShape (BitVec outputWidth) :=
  fun index => repack inputOrder outputOrder same
    (fun cell => input (LinearIndex.delinearize inputShape cell))
    (LinearIndex.linearize outputShape index)

/-- Reinterpret actual dense-layout storage, then observe output words through its own layout. -/
def physicalConvert {inputRank outputRank inputWidth outputWidth : Nat}
    {inputShape : Shape inputRank} (inputLayout : DenseLayout inputRank)
    (outputLayout : DenseLayout outputRank) (outputShape : Shape outputRank)
    (inputOrder outputOrder : Order)
    (same : LinearIndex.elementCount (inputLayout.orderedShape inputShape) * inputWidth =
      LinearIndex.elementCount (outputLayout.orderedShape outputShape) * outputWidth)
    (input : Tensor inputShape (BitVec inputWidth)) : Tensor outputShape (BitVec outputWidth) :=
  outputLayout.read (repack inputOrder outputOrder same (inputLayout.write input))

/-- Append the actual rank-changing word-ratio dimension, retaining every original axis. -/
def appendAxis : {rank : Nat} → Shape rank → Nat → Shape (rank + 1)
  | 0, _, extent => fun _ => extent
  | _ + 1, shape, extent => Fin.cases (shape 0) (appendAxis (fun axis => shape axis.succ) extent)

end TensorRewrite.Theory.BitPacking
