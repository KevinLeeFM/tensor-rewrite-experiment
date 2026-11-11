module

public import TensorRewrite.Theory.BitPackingShapeProof
public import TensorRewrite.Theory.BitPackingCell

/-! Explicit representation, bit-order, layout and empty-count diagnostics. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BitPacking

open Pilot

/-- Two different actual byte values in physical cell order. -/
def bytePair : Words 2 8 := Fin.cases 0x12 (fun _ => 0x34)

/-- Changing the declared packing order changes the joined word's stored representation. -/
theorem bit_order_refuted :
    repack (outputWidth := 16) .leastFirst .leastFirst (by decide) bytePair (0 : Fin 1) ≠
      repack (outputWidth := 16) .mostFirst .mostFirst (by decide) bytePair (0 : Fin 1) := by decide

/-- Numerically extending one byte cannot replace actual packing of two stored bytes. -/
theorem numeric_extension_refuted :
    repack (outputWidth := 16) .leastFirst .leastFirst (by decide) bytePair (0 : Fin 1) ≠
      (bytePair 0).zeroExtend 16 := by decide

/-- A nontrivial logical matrix makes row-major and column-major cell observations differ. -/
def matrixInput : Tensor (fun _ : Fin 2 => 2) (BitVec 8) :=
  fun index => BitVec.ofNat 8 (10 * (index 0).val + (index 1).val)

/-- Changing output cell order cannot be erased merely because logical shapes agree. -/
theorem layout_identity_refuted :
    physicalConvert (DenseLayout.rowMajor 2) (DenseLayout.columnMajor 2)
        (fun _ => 2) .leastFirst .leastFirst (by decide) matrixInput
        (fun axis => if axis = 0 then 0 else 1) ≠
      matrixInput (fun axis => if axis = 0 then 0 else 1) := by decide

/-- Equal total storage bits do not determine element width in an empty tensor. -/
theorem empty_width_inference_refuted :
    (0 * 8 = 0 * 16) ∧ (8 : Nat) ≠ 16 := by decide

end TensorRewrite.Theory.BitPacking
