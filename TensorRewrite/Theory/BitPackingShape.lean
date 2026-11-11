module

public import TensorRewrite.Theory.BitPackingLemmas

/-! Actual trailing-ratio shape construction for splitting and joining stored word widths. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BitPacking

open Pilot

/-- Split each word by adding a trailing ratio dimension with independently derived bit count. -/
def splitLast {rank width : Nat} {shape : Shape rank} (factor : Nat) (order : Order)
    (input : Tensor shape (BitVec (factor * width))) :
    Tensor (appendAxis shape factor) (BitVec width) :=
  physicalConvert (DenseLayout.rowMajor rank) (DenseLayout.rowMajor (rank + 1))
    (appendAxis shape factor) order order (physical_split_bit_count shape factor width) input

/-- Join the complete trailing ratio dimension into each output word. -/
def joinLast {rank width : Nat} (shape : Shape rank) (factor : Nat) (order : Order)
    (input : Tensor (appendAxis shape factor) (BitVec width)) :
    Tensor shape (BitVec (factor * width)) :=
  physicalConvert (DenseLayout.rowMajor (rank + 1)) (DenseLayout.rowMajor rank) shape
    order order (physical_split_bit_count shape factor width).symm input

end TensorRewrite.Theory.BitPacking
