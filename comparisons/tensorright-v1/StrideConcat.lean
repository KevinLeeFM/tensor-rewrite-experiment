module

public import TensorRewrite.Pilot.IndexMapLemmas
public import Mathlib.Tactic.Ring

/-! The paper's arbitrary-stride Slice after three-way Concat. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.StrideConcat

open Pilot

/-- Remove the leading segment's length from both Slice bounds. -/
def shifted (leading : Nat) (axis : SliceShape.Axis) : SliceShape.Axis where
  start := axis.start - leading
  limit := axis.limit - leading
  stride := axis.stride

/-- Paper-valid bounds past the first segment remain valid with the same inferred size. -/
theorem shifted_valid (leading tail length : Nat) (axis : SliceShape.Axis)
    (valid : SliceShape.IsWellFormed (leading + tail) length axis)
    (after : (leading : Int) ≤ axis.start) :
    SliceShape.IsWellFormed tail length (shifted leading axis) := by
  rcases valid with ⟨nonnegative, ordered, limited, positive, lengthNonnegative, count⟩
  refine ⟨by simp [shifted]; omega, by simp [shifted]; omega, by simp [shifted]; omega,
    positive, lengthNonnegative, ?_⟩
  unfold SliceShape.Axis.elementCount shifted
  have same : axis.limit - leading - (axis.start - leading) + axis.stride - 1 =
      axis.limit - axis.start + axis.stride - 1 := by ring
  rw [same]
  exact count

/-- A one-axis paper Slice uses its actual start and positive stride. -/
def sliceAxis {size length : Nat} {α : Type} (axis : SliceShape.Axis)
    (valid : SliceShape.IsWellFormed size length axis) (input : Fin size → α) : Fin length → α :=
  fun index =>
    let coordinate := axis.start + axis.stride * (index.val : Int)
    have bound := SliceShape.coordinate_bounds valid index.val (by omega) (by
      have bound := index.isLt
      omega)
    input ⟨coordinate.toNat, (Int.toNat_lt bound.1).mpr bound.2⟩

/-- The bounded Slice index is exactly the paper's signed affine expression. -/
theorem slice_coordinate {size length : Nat} (axis : SliceShape.Axis)
    (valid : SliceShape.IsWellFormed size length axis) (index : Fin length) :
    ((sliceAxis axis valid id index).val : Int) = axis.start + axis.stride * index.val := by
  unfold sliceAxis
  apply Int.toNat_of_nonneg
  exact (SliceShape.coordinate_bounds valid index.val (by omega) (by
    have bound := index.isLt
    omega)).1

/-- The one-axis Slice coordinate is the actual coordinate of the bounded tensor Slice model. -/
theorem matches_index_map {rank : Nat} {inputShape outputShape : Shape rank}
    (axes : Fin rank → SliceShape.Axis)
    (valid : ∀ axis, SliceShape.IsWellFormed (inputShape axis) (outputShape axis) (axes axis))
    (output : Index outputShape) (axis : Fin rank) :
    (sliceAxis (axes axis) (valid axis) id (output axis)).val =
      (IndexMaps.sliceIndex axes valid output axis).val := by
  have scalar := slice_coordinate (axes axis) (valid axis) (output axis)
  have tensor := IndexMaps.sliceIndex_val axes valid output axis
  exact_mod_cast scalar.trans tensor.symm

/-- `slice/rule12`: discard the leading Concat segment under the paper's offset guard. -/
theorem skip_first {α : Type} {first second third length : Nat}
    (a : Fin first → α) (b : Fin second → α) (c : Fin third → α)
    (axis : SliceShape.Axis)
    (valid : SliceShape.IsWellFormed (first + (second + third)) length axis)
    (after : (first : Int) ≤ axis.start) :
    sliceAxis axis valid (fun index => (Fin.addCases a (Fin.addCases b c) index : α)) =
      sliceAxis (shifted first axis) (shifted_valid first (second + third) length axis valid after)
        (fun index => (Fin.addCases b c index : α)) := by
  funext index
  have outer := slice_coordinate axis valid index
  have inner := slice_coordinate (shifted first axis)
    (shifted_valid first (second + third) length axis valid after) index
  have innerStart : (shifted first axis).start = axis.start - first := rfl
  have innerStride : (shifted first axis).stride = axis.stride := rfl
  rw [innerStart, innerStride] at inner
  have indices : sliceAxis axis valid id index = Fin.natAdd first
      (sliceAxis (shifted first axis)
        (shifted_valid first (second + third) length axis valid after) id index) := by
    apply Fin.ext
    simp only [Fin.val_natAdd]
    omega
  change (Fin.addCases a (Fin.addCases b c) (sliceAxis axis valid id index) : α) =
    (Fin.addCases b c (sliceAxis (shifted first axis)
      (shifted_valid first (second + third) length axis valid after) id index) : α)
  rw [indices, Fin.addCases_right]

#print axioms shifted_valid
#print axioms matches_index_map
#print axioms slice_coordinate
#print axioms skip_first

end TensorRewrite.PaperComparison.StrideConcat
