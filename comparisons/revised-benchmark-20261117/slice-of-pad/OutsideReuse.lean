module
public import SlicePadSpec
public section
set_option autoImplicit false
namespace TensorRewrite.PaperComparison.SignedPad
open Pilot Theory
/-- Every valid static Slice coordinate is strictly below its exclusive limit. -/
theorem coordinate_lt_limit {extent length : Int} {axis : SliceShape.Axis}
    (valid : SliceShape.IsWellFormed extent length axis) (index : Int)
    (_nonnegative : 0 ≤ index) (bounded : index < length) :
    axis.start + axis.stride * index < axis.limit := by
  rcases valid with ⟨startNonnegative, ordered, limited, positive, outNonnegative, count⟩
  have numerator : 0 ≤ axis.limit - axis.start + axis.stride - 1 := by omega
  have product : axis.stride * length ≤ axis.limit - axis.start + axis.stride - 1 := by
    rw [← count]
    exact Int.mul_tdiv_self_le numerator
  have step : axis.stride * (index + 1) ≤ axis.stride * length :=
    Int.mul_le_mul_of_nonneg_left (by omega) (by omega)
  rw [Int.mul_add, Int.mul_one] at step
  omega

/-- Positions outside the paper's occupied span cannot sample an original input value. -/
theorem sample_outside (size : Nat) (low position : Int) (interior : Nat)
    (outside : position < low ∨
      low + (size : Int) + ((size : Int) - 1) * interior ≤ position) :
    sample size low interior position = none := by
  cases found : sample size low interior position with
  | none => rfl
  | some index =>
    have location := (sample_some size low interior position index).mp found
    have bound := index.isLt
    have indexBound : (index.val : Int) ≤ (size : Int) - 1 := by omega
    have spacingNonnegative : (0 : Int) ≤ (interior : Int) + 1 := by omega
    have product := Int.mul_le_mul_of_nonneg_right indexBound spacingNonnegative
    have productNonnegative : 0 ≤ (index.val : Int) * ((interior : Int) + 1) :=
      Int.mul_nonneg (by omega) spacingNonnegative
    have normalized : ((size : Int) - 1) * ((interior : Int) + 1) + 1 =
        (size : Int) + ((size : Int) - 1) * interior := by
      rw [Int.mul_add, Int.sub_mul, Int.mul_one, Int.one_mul]
      omega
    omega

/-- `slice/rule05`: a Slice wholly outside one occupied axis is a fill tensor. -/
theorem slice_outside {rank : Nat} {inputShape paddedShape outputShape : Shape rank} {α : Type}
    (params : Params inputShape paddedShape) (axes : Fin rank → SliceShape.Axis)
    (valid : ∀ axis, SliceShape.IsWellFormed (paddedShape axis) (outputShape axis) (axes axis))
    (axis : Fin rank)
    (outside : (axes axis).limit ≤ params.low axis ∨
      params.low axis + (inputShape axis : Int) +
        ((inputShape axis : Int) - 1) * params.interior axis ≤ (axes axis).start)
    (fill : α) (input : Tensor inputShape α) :
    (fun output => tensor params fill input (IndexMaps.sliceIndex axes valid output)) =
      Tensor.constant fill := by
  funext output
  let position := IndexMaps.sliceIndex axes valid output
  have coordinate := IndexMaps.sliceIndex_val axes valid output axis
  have bound := (output axis).isLt
  have beforeLimit := coordinate_lt_limit (valid axis) (output axis).val (by omega) (by omega)
  have positive := (valid axis).2.2.2.1
  have product : 0 ≤ (axes axis).stride * ((output axis).val : Int) :=
    Int.mul_nonneg (by omega) (by omega)
  have outsidePosition : ((position axis).val : Int) < params.low axis ∨
      params.low axis + (inputShape axis : Int) +
        ((inputShape axis : Int) - 1) * params.interior axis ≤ (position axis).val := by
    dsimp only [position]
    omega
  have absent := sample_outside (inputShape axis) (params.low axis) (position axis).val
    (params.interior axis) outsidePosition
  have notAll : ¬ (∀ i, (sample (inputShape i) (params.low i) (params.interior i)
      (position i).val).isSome) := by
    intro all
    have chosen := all axis
    rw [absent] at chosen
    contradiction
  unfold tensor selected LatticeIndex.assemble?
  rw [dite_eq_right notAll]
  rfl

end TensorRewrite.PaperComparison.SignedPad
