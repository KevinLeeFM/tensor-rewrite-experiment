module

public import TensorRewrite.Pilot.DynamicSliceComposition

/-! Finite-word witness for the failed-Iota-probe nested-DynamicSlice path.
This model retains the multiplication present in the original input graph.
It does not assume the source's mutable local operand still names that graph. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.ScaledNestedSlice

open DynamicIndex

/-- A rank-one extent, including scalar-sized and empty vectors. -/
def shape (extent : Nat) : Shape 1 := fun _ => extent

/-- Nonuniform source labels one through ten, encoded as S32 interchange words. -/
def data : Tensor (shape 10) (BitVec 32) := fun index => BitVec.ofNat 32 ((index 0).val + 1)

/-- The original graph slices six elements, scales them, then takes the outer slice. -/
def original (width : Nat) (fits : width ≤ 6) (multiplier : BitVec 32)
    (inner outer : Int) : Tensor (shape width) (BitVec 32) :=
  let sliced := sliceTensor (outputShape := shape 6) data (fun _ => inner)
    (by intro axis; exact (by decide : 6 ≤ 10))
  sliceTensor (Tensor.map (fun value => value * multiplier) sliced)
    (fun _ => outer) (fun _ => fits)

/-- The source continuation selects from the unscaled base at the combined start. -/
def rewritten (width : Nat) (fits : width ≤ 6) (inner outer : Int) :
    Tensor (shape width) (BitVec 32) :=
  sliceTensor data (fun _ => combinedStart 10 6 width inner outer)
    (by intro axis; exact Nat.le_trans fits (by decide : 6 ≤ 10))

/-- The sole coordinate of a width-one result. -/
def witnessIndex : Index (shape 1) := fun _ => ⟨0, by decide +revert⟩

end TensorRewrite.Pilot.ScaledNestedSlice
