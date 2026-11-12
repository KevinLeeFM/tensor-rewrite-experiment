module

public import TensorRewrite.Theory.SlicePadLemmas
public import TensorRewrite.Pilot.IndexMapLemmas

/-! Paper Slice after zero-interior nonnegative edge Pad. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.PadSlice

open Pilot Theory Theory.SlicePad

/-- Subtract the actual low padding from both static Slice bounds. -/
def translated (low : Nat) (axis : SliceShape.Axis) : SliceShape.Axis where
  start := axis.start - low
  limit := axis.limit - low
  stride := 1

/-- Paper bounds yield a valid equally sized Slice on the unpadded operand. -/
theorem translated_valid (inner low high length : Nat) (axis : SliceShape.Axis)
    (valid : SliceShape.IsWellFormed (low + inner + high) length axis)
    (startBound : (low : Int) ≤ axis.start) (endBound : axis.limit ≤ (inner : Int) + low)
    (unit : axis.stride = 1) :
    SliceShape.IsWellFormed inner length (translated low axis) := by
  rcases valid with ⟨nonnegative, ordered, limited, positive, outNonnegative, count⟩
  have counted := count
  simp [SliceShape.Axis.elementCount, unit] at counted
  unfold SliceShape.IsWellFormed translated SliceShape.Axis.elementCount
  simp
  omega

/-- `slice/rule06`: crop inside Pad, then subtract low padding from both bounds. -/
theorem slice_after_pad {rank : Nat} {α : Type} (padding : Padding rank)
    (inner outputShape : Shape rank) (axes : Fin rank → SliceShape.Axis)
    (valid : ∀ axis, SliceShape.IsWellFormed (padding.outputShape inner axis)
      (outputShape axis) (axes axis))
    (startBound : ∀ axis, (padding.low axis : Int) ≤ (axes axis).start)
    (endBound : ∀ axis, (axes axis).limit ≤ (inner axis : Int) + padding.low axis)
    (unit : ∀ axis, (axes axis).stride = 1) (fill : α) (input : Tensor inner α) :
    (fun output => padding.tensor fill input (IndexMaps.sliceIndex axes valid output)) =
      (fun output => input (IndexMaps.sliceIndex
        (fun axis => translated (padding.low axis) (axes axis))
        (fun axis => translated_valid (inner axis) (padding.low axis) (padding.high axis)
          (outputShape axis) (axes axis) (valid axis) (startBound axis) (endBound axis)
          (unit axis)) output)) := by
  funext output
  let paddedIndex := IndexMaps.sliceIndex axes valid output
  have inPad : ∀ axis, (ReductionWindow.boundedIndex? (inner axis)
      ((paddedIndex axis).val - (padding.low axis : Int))).isSome := by
    intro axis
    dsimp only [paddedIndex]
    apply (bounded_isSome _ _).mpr
    have coordinate := IndexMaps.sliceIndex_val axes valid output axis
    have count := (valid axis).2.2.2.2.2
    have bounded := (output axis).isLt
    have lower := startBound axis
    have upper := endBound axis
    simp [SliceShape.Axis.elementCount, unit axis] at count
    rw [unit axis] at coordinate
    simp only [one_mul] at coordinate
    omega
  unfold Padding.tensor Padding.input?
  rw [dite_eq_left inPad]
  apply congrArg input
  funext axis
  apply Fin.ext
  have padCoordinate := bounded_value (inner axis)
    ((paddedIndex axis).val - (padding.low axis : Int)) (inPad axis)
  have outerCoordinate := IndexMaps.sliceIndex_val axes valid output axis
  have innerCoordinate := IndexMaps.sliceIndex_val
    (fun axis => translated (padding.low axis) (axes axis))
    (fun axis => translated_valid (inner axis) (padding.low axis) (padding.high axis)
      (outputShape axis) (axes axis) (valid axis) (startBound axis) (endBound axis)
      (unit axis)) output axis
  simp only [translated, one_mul] at innerCoordinate
  rw [unit axis] at outerCoordinate
  simp only [one_mul] at outerCoordinate
  change (((ReductionWindow.boundedIndex? (inner axis)
    ((paddedIndex axis).val - (padding.low axis : Int))).get (inPad axis)).val) = _
  dsimp only [paddedIndex, translated] at *
  omega

#print axioms translated_valid
#print axioms slice_after_pad

end TensorRewrite.PaperComparison.PadSlice
