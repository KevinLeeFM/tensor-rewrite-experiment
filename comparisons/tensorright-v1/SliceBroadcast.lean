module

public import TensorRewrite.Pilot.IndexMapLemmas
public import TensorRewrite.Pilot.DynamicIndexLemmas
public import Mathlib.Algebra.EuclideanDomain.Int

/-! Static Slice and Broadcast on actual bounded axis projections. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.SliceBroadcast

open Pilot Pilot.IndexMaps

/-- The matching paper Slice attributes infer the same sizes on retained axes. -/
theorem retained_size {inputRank outputRank : Nat}
    {inputShape inputSliceShape : Shape inputRank}
    {broadcastShape outputShape : Shape outputRank}
    (axes : BroadcastAxes inputRank outputRank)
    (outerAxes : Fin outputRank → SliceShape.Axis) (innerAxes : Fin inputRank → SliceShape.Axis)
    (outerValid : ∀ axis, SliceShape.IsWellFormed (broadcastShape axis) (outputShape axis)
      (outerAxes axis))
    (innerValid : ∀ axis, SliceShape.IsWellFormed (inputShape axis) (inputSliceShape axis)
      (innerAxes axis))
    (starts : ∀ axis, (innerAxes axis).start = (outerAxes (axes.decode axis)).start)
    (limits : ∀ axis, (innerAxes axis).limit = (outerAxes (axes.decode axis)).limit)
    (strides : ∀ axis, (innerAxes axis).stride = (outerAxes (axes.decode axis)).stride)
    (axis : Fin inputRank) : inputSliceShape axis = outputShape (axes.decode axis) := by
  have inner := (innerValid axis).2.2.2.2.2
  have outer := (outerValid (axes.decode axis)).2.2.2.2.2
  unfold SliceShape.Axis.elementCount at inner outer
  rw [starts axis, limits axis, strides axis] at inner
  omega

/-- `slice/rule03`: slicing a Broadcast projects to slicing the retained input axes. -/
theorem commute {inputRank outputRank : Nat}
    {inputShape inputSliceShape : Shape inputRank}
    {broadcastShape outputShape : Shape outputRank} {α : Type}
    (input : Tensor inputShape α) (axes : BroadcastAxes inputRank outputRank)
    (oldExtents : ∀ axis, inputShape axis = broadcastShape (axes.decode axis))
    (newExtents : ∀ axis, inputSliceShape axis = outputShape (axes.decode axis))
    (outerAxes : Fin outputRank → SliceShape.Axis) (innerAxes : Fin inputRank → SliceShape.Axis)
    (outerValid : ∀ axis, SliceShape.IsWellFormed (broadcastShape axis) (outputShape axis)
      (outerAxes axis))
    (innerValid : ∀ axis, SliceShape.IsWellFormed (inputShape axis) (inputSliceShape axis)
      (innerAxes axis))
    (starts : ∀ axis, (innerAxes axis).start = (outerAxes (axes.decode axis)).start)
    (strides : ∀ axis, (innerAxes axis).stride = (outerAxes (axes.decode axis)).stride) :
    (fun output => input
      (broadcastIndex axes oldExtents (sliceIndex outerAxes outerValid output))) =
      (fun output => input
        (sliceIndex innerAxes innerValid (broadcastIndex axes newExtents output))) := by
  funext output
  apply congrArg input
  funext axis
  apply Fin.ext
  have outer := sliceIndex_val outerAxes outerValid output (axes.decode axis)
  have inner := sliceIndex_val innerAxes innerValid (broadcastIndex axes newExtents output) axis
  have projection := broadcastIndex_val axes newExtents output axis
  have original := broadcastIndex_val axes oldExtents (sliceIndex outerAxes outerValid output) axis
  rw [starts axis, strides axis] at inner
  simp only [projection] at inner
  have result :
      ((broadcastIndex axes oldExtents (sliceIndex outerAxes outerValid output) axis).val : Int) =
        ((sliceIndex innerAxes innerValid (broadcastIndex axes newExtents output) axis).val
          : Int) := by
    rw [original]
    exact outer.trans inner.symm
  exact_mod_cast result

/-- The paper's quotient/remainder ceiling equals the ordinary positive-stride Slice count. -/
theorem ceil_quotient (distance stride : Int) (positive : 0 < stride) :
    (distance + stride - 1) / stride =
      if distance % stride = 0 then distance / stride else distance / stride + 1 := by
  have nonzero : stride ≠ 0 := by omega
  have lower := Int.emod_nonneg distance nonzero
  have upper := Int.emod_lt_of_pos distance positive
  have decomposition := Int.emod_add_ediv_mul distance stride
  have form : distance + stride - 1 =
      (distance / stride) * stride + (distance % stride + stride - 1) := by omega
  rw [form, Int.mul_add_ediv_right _ _ nonzero]
  by_cases zero : distance % stride = 0
  · rw [ite_eq_left zero, zero]
    have small : (stride - 1) / stride = 0 := Int.ediv_eq_zero_of_lt (by omega) (by omega)
    simp [small]
  · rw [ite_eq_right zero]
    have remaining : distance % stride + stride - 1 =
        1 * stride + (distance % stride - 1) := by omega
    have small : (distance % stride - 1) / stride = 0 :=
      Int.ediv_eq_zero_of_lt (by omega) (by omega)
    rw [remaining, Int.mul_add_ediv_right _ _ nonzero, small]
    simp

/-- The paper's piecewise Broadcast size equals the inferred static Slice count. -/
theorem paper_ceil_count (axis : SliceShape.Axis) (extent length : Nat)
    (valid : SliceShape.IsWellFormed extent length axis) :
    (if (axis.limit - axis.start) % axis.stride = 0 then
      (axis.limit - axis.start) / axis.stride
    else (axis.limit - axis.start) / axis.stride + 1) = (length : Int) := by
  have positive := valid.2.2.2.1
  have numerator : 0 ≤ axis.limit - axis.start + axis.stride - 1 := by
    have ordered := valid.2.1
    omega
  have count := valid.2.2.2.2.2
  unfold SliceShape.Axis.elementCount at count
  rw [Int.tdiv_eq_ediv_of_nonneg numerator] at count
  exact (ceil_quotient (axis.limit - axis.start) axis.stride positive).symm.trans count

/-- A retained full Slice on the input axes disappears after commuting with Broadcast. -/
theorem full_retained {inputRank outputRank : Nat}
    {inputShape : Shape inputRank} {broadcastShape outputShape : Shape outputRank} {α : Type}
    (input : Tensor inputShape α) (axes : BroadcastAxes inputRank outputRank)
    (oldExtents : ∀ axis, inputShape axis = broadcastShape (axes.decode axis))
    (newExtents : ∀ axis, inputShape axis = outputShape (axes.decode axis))
    (outerAxes : Fin outputRank → SliceShape.Axis) (innerAxes : Fin inputRank → SliceShape.Axis)
    (outerValid : ∀ axis, SliceShape.IsWellFormed (broadcastShape axis) (outputShape axis)
      (outerAxes axis))
    (innerValid : ∀ axis, SliceShape.IsWellFormed (inputShape axis) (inputShape axis)
      (innerAxes axis))
    (starts : ∀ axis, (innerAxes axis).start = (outerAxes (axes.decode axis)).start)
    (strides : ∀ axis, (innerAxes axis).stride = (outerAxes (axes.decode axis)).stride)
    (zeroStarts : ∀ axis, (innerAxes axis).start = 0)
    (unitStrides : ∀ axis, (innerAxes axis).stride = 1) :
    (fun output => input
      (broadcastIndex axes oldExtents (sliceIndex outerAxes outerValid output))) =
      (fun output => input (broadcastIndex axes newExtents output)) := by
  rw [commute input axes oldExtents newExtents outerAxes innerAxes outerValid innerValid
    starts strides]
  funext output
  apply congrArg input
  funext axis
  apply Fin.ext
  have coordinate := sliceIndex_val innerAxes innerValid
    (broadcastIndex axes newExtents output) axis
  rw [zeroStarts axis, unitStrides axis] at coordinate
  simp at coordinate
  exact_mod_cast coordinate

/-- Paper-valid dynamic starts are unchanged by the existing clamped index model. -/
theorem dynamic_start (extent length : Nat) (start : Int)
    (valid : 0 ≤ start ∧ start + length ≤ extent) :
    DynamicIndex.clampStart extent length start = start := by
  unfold DynamicIndex.clampStart
  omega

/-- `dyslice/rule03`: DynamicSlice commutes with Broadcast's retained-axis projection. -/
theorem dynamic_commute {inputRank outputRank : Nat}
    {inputShape inputSliceShape : Shape inputRank}
    {broadcastShape outputShape : Shape outputRank} {α : Type}
    (input : Tensor inputShape α) (axes : BroadcastAxes inputRank outputRank)
    (oldExtents : ∀ axis, inputShape axis = broadcastShape (axes.decode axis))
    (newExtents : ∀ axis, inputSliceShape axis = outputShape (axes.decode axis))
    (outerStarts : Fin outputRank → Int) (innerStarts : Fin inputRank → Int)
    (outerFits : ∀ axis, outputShape axis ≤ broadcastShape axis)
    (innerFits : ∀ axis, inputSliceShape axis ≤ inputShape axis)
    (starts : ∀ axis, innerStarts axis = outerStarts (axes.decode axis)) :
    (fun output => input (broadcastIndex axes oldExtents
      (DynamicIndex.dynamicSliceIndex outerStarts outerFits output))) =
      (fun output => input (DynamicIndex.dynamicSliceIndex innerStarts innerFits
        (broadcastIndex axes newExtents output))) := by
  funext output
  apply congrArg input
  funext axis
  apply Fin.ext
  have outer := DynamicIndex.dynamicSliceIndex_val outerStarts outerFits output (axes.decode axis)
  have inner := DynamicIndex.dynamicSliceIndex_val innerStarts innerFits
    (broadcastIndex axes newExtents output) axis
  have projection := broadcastIndex_val axes newExtents output axis
  have original := broadcastIndex_val axes oldExtents
    (DynamicIndex.dynamicSliceIndex outerStarts outerFits output) axis
  have sameClamp :
      DynamicIndex.clampStart (inputShape axis) (inputSliceShape axis) (innerStarts axis) =
        DynamicIndex.clampStart (broadcastShape (axes.decode axis))
          (outputShape (axes.decode axis)) (outerStarts (axes.decode axis)) := by
    rw [oldExtents axis, newExtents axis, starts axis]
  rw [sameClamp] at inner
  simp only [projection] at inner
  have result :
      ((broadcastIndex axes oldExtents
        (DynamicIndex.dynamicSliceIndex outerStarts outerFits output) axis).val : Int) =
        ((DynamicIndex.dynamicSliceIndex innerStarts innerFits
          (broadcastIndex axes newExtents output) axis).val : Int) := by
    rw [original]
    exact outer.trans inner.symm
  exact_mod_cast result

#print axioms dynamic_start
#print axioms dynamic_commute
#print axioms ceil_quotient
#print axioms paper_ceil_count
#print axioms full_retained
#print axioms retained_size
#print axioms commute

end TensorRewrite.PaperComparison.SliceBroadcast
