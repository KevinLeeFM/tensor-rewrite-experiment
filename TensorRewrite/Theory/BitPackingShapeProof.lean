module

public import TensorRewrite.Theory.BitPackingShape
public import TensorRewrite.Theory.BitPackingProof

/-! Rank-changing split/join round trips through actual word and standard dense-layout maps. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BitPacking

open Pilot

/-- Appending then removing the actual ratio dimension preserves every input representation. -/
theorem join_split {rank width : Nat} {shape : Shape rank} (factor : Nat) (order : Order)
    (input : Tensor shape (BitVec (factor * width))) :
    joinLast shape factor order (splitLast factor order input) = input := by
  unfold joinLast splitLast
  rw [physical_convert_compose]
  exact physical_convert_refl _ order input

/-- Removing then restoring the actual trailing ratio dimension preserves every input bit. -/
theorem split_join {rank width : Nat} (shape : Shape rank) (factor : Nat) (order : Order)
    (input : Tensor (appendAxis shape factor) (BitVec width)) :
    splitLast factor order (joinLast shape factor order input) = input := by
  unfold joinLast splitLast
  rw [physical_convert_compose]
  exact physical_convert_refl _ order input

end TensorRewrite.Theory.BitPacking
