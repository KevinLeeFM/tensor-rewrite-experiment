module

public import TensorRewrite.Theory.SlicePadLemmas

/-! Paper-era constant Slice rules and their exact output-shape conditions. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Slices

open Pilot Theory.SlicePad

/-- A legal Slice count uses the paper's Euclidean division when the numerator is nonnegative. -/
theorem count_euclidean (axis : SliceShape.Axis) (extent length : Nat)
    (valid : SliceShape.IsWellFormed extent length axis) :
    (axis.limit - axis.start + axis.stride - 1) / axis.stride = (length : Int) := by
  have numerator : 0 ≤ axis.limit - axis.start + axis.stride - 1 := by
    obtain ⟨_, ordered, _, stride, _, _⟩ := valid
    omega
  have equality := valid.2.2.2.2.2
  unfold SliceShape.Axis.elementCount at equality
  rw [Int.tdiv_eq_ediv_of_nonneg numerator] at equality
  exact equality

/-- A limit exactly `length * stride` after start infers precisely `length` output values. -/
theorem count_exact (axis : SliceShape.Axis) (length : Nat)
    (positive : 0 < axis.stride)
    (limit : axis.limit = axis.start + (length : Int) * axis.stride) :
    axis.elementCount = (length : Int) := by
  have numerator : 0 ≤ axis.limit - axis.start + axis.stride - 1 := by
    rw [limit]
    have product := Int.mul_nonneg (show 0 ≤ (length : Int) by omega) (by omega : 0 ≤ axis.stride)
    omega
  have form : axis.limit - axis.start + axis.stride - 1 =
      (length : Int) * axis.stride + (axis.stride - 1) := by rw [limit]; ring
  unfold SliceShape.Axis.elementCount
  rw [Int.tdiv_eq_ediv_of_nonneg numerator, form,
    Int.mul_add_ediv_right _ _ (by omega), Int.ediv_eq_zero_of_lt (by omega) (by omega)]
  simp

/-- `slice/rule02` and `broadcast/rule05`: Slice of a constant has the inferred output shape. -/
theorem slice_constant {rank : Nat} {α : Type} (slice : Slice rank) (value : α) :
    slice.tensor (Tensor.constant value) = Tensor.constant value := rfl

/-- A paper-style DynamicSlice reads starts directly, under the paper's in-bounds conditions. -/
def dynamicSlice {rank : Nat} {inputShape outputShape : Shape rank}
    (starts : Fin rank → Int)
    (valid : ∀ axis, 0 ≤ starts axis ∧ starts axis + outputShape axis ≤ inputShape axis)
    {α : Type} (input : Tensor inputShape α) : Tensor outputShape α := fun index =>
  input fun axis =>
    let coordinate : Int := starts axis + (index axis).val
    have bounds : 0 ≤ coordinate ∧ coordinate < inputShape axis := by
      have source := valid axis
      have bounded := (index axis).isLt
      omega
    ⟨coordinate.toNat, (Int.toNat_lt bounds.1).mpr bounds.2⟩

/-- `broadcast/rule06`: a valid DynamicSlice of a uniform tensor is uniform. -/
theorem dynamic_slice_constant {rank : Nat} {inputShape outputShape : Shape rank}
    (starts : Fin rank → Int)
    (valid : ∀ axis, 0 ≤ starts axis ∧ starts axis + outputShape axis ≤ inputShape axis)
    {α : Type} (value : α) :
    dynamicSlice starts valid (Tensor.constant (shape := inputShape) value) =
      Tensor.constant (shape := outputShape) value := rfl

#print axioms count_euclidean
#print axioms count_exact
#print axioms slice_constant
#print axioms dynamic_slice_constant

end TensorRewrite.PaperComparison.Slices
