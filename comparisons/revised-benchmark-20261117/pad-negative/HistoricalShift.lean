module
public import NegativeSpec
public section
set_option autoImplicit false
namespace TensorRewrite.PaperComparison.SignedPad
open Pilot Theory
/-- `pad/rule04`: translate Pad's low edge through a valid Slice, axis by axis. -/
theorem pad_shift {rank : Nat} {inputShape outputShape intermediateShape : Shape rank} {α : Type}
    (first : Params inputShape outputShape) (second : Params inputShape intermediateShape)
    (axes : Fin rank → SliceShape.Axis)
    (valid : ∀ axis, SliceShape.IsWellFormed (intermediateShape axis)
      (outputShape axis) (axes axis))
    (starts : ∀ axis, (axes axis).start = second.low axis - first.low axis)
    (strides : ∀ axis, (axes axis).stride = 1)
    (interiors : ∀ axis, first.interior axis = second.interior axis)
    (fill : α) (input : Tensor inputShape α) :
    tensor first fill input = fun output =>
      tensor second fill input (IndexMaps.sliceIndex axes valid output) := by
  funext output
  have samples : (fun axis => sample (inputShape axis) (first.low axis) (first.interior axis)
        (output axis).val) =
      (fun axis => sample (inputShape axis) (second.low axis) (second.interior axis)
        (IndexMaps.sliceIndex axes valid output axis).val) := by
    funext axis
    have coordinate := IndexMaps.sliceIndex_val axes valid output axis
    rw [starts axis, strides axis] at coordinate
    simp only [one_mul] at coordinate
    have offsets : ((output axis).val : Int) - first.low axis =
        ((IndexMaps.sliceIndex axes valid output axis).val : Int) - second.low axis := by omega
    unfold sample
    rw [interiors axis, offsets]
  unfold tensor selected
  rw [samples]

end TensorRewrite.PaperComparison.SignedPad
