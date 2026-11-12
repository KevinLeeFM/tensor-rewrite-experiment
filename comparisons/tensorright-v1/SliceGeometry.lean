module

public import TensorRewrite.Theory.SlicePadLemmas
public import TensorRewrite.Pilot.IndexMapLemmas

/-! Static paper Slice rules with bounded coordinates and inferred shapes. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.SliceGeometry

open Pilot Theory.SlicePad

/-- Full unit-stride Slice infers exactly the original input shape. -/
theorem full_shape {rank : Nat} (slice : Slice rank)
    (starts : ∀ axis, (slice.axes axis).start = 0)
    (limits : ∀ axis, (slice.axes axis).limit = slice.inputShape axis)
    (strides : ∀ axis, (slice.axes axis).stride = 1) :
    slice.outputShape = slice.inputShape := by
  funext axis
  have count := (slice.valid axis).2.2.2.2.2
  unfold SliceShape.Axis.elementCount at count
  rw [starts axis, limits axis, strides axis] at count
  simp at count
  exact_mod_cast count.symm

/-- `slice/rule01`: full unit-stride Slice reads each original coordinate. -/
theorem full {rank : Nat} {shape : Shape rank} {α : Type} (input : Tensor shape α)
    (axes : Fin rank → SliceShape.Axis)
    (valid : ∀ axis, SliceShape.IsWellFormed (shape axis) (shape axis) (axes axis))
    (starts : ∀ axis, (axes axis).start = 0)
    (strides : ∀ axis, (axes axis).stride = 1) :
    (fun index => input (IndexMaps.sliceIndex axes valid index)) = input := by
  funext index
  apply congrArg input
  funext axis
  apply Fin.ext
  have coordinate := IndexMaps.sliceIndex_val axes valid index axis
  rw [starts axis, strides axis] at coordinate
  simp at coordinate
  exact_mod_cast coordinate

/-- The paper's nested-Slice limit and start infer the same length on each axis. -/
theorem nested_count (outer combined : SliceShape.Axis) (middleExtent inputExtent : Nat)
    (outerLength combinedLength : Nat)
    (outerValid : SliceShape.IsWellFormed middleExtent outerLength outer)
    (combinedValid : SliceShape.IsWellFormed inputExtent combinedLength combined)
    (base : Int) (start : combined.start = base + outer.start)
    (limit : combined.limit = base + outer.limit)
    (outerStride : outer.stride = 1) (combinedStride : combined.stride = 1) :
    outerLength = combinedLength := by
  have a := outerValid.2.2.2.2.2
  have b := combinedValid.2.2.2.2.2
  unfold SliceShape.Axis.elementCount at a b
  rw [outerStride] at a
  rw [combinedStride, start, limit] at b
  simp at a b
  omega

/-- `slice/rule07`: composed unit-stride Slice reads the same bounded input coordinates. -/
theorem nested {rank : Nat} {inputShape middleShape outputShape : Shape rank} {α : Type}
    (input : Tensor inputShape α) (inner outer combined : Fin rank → SliceShape.Axis)
    (innerValid : ∀ axis, SliceShape.IsWellFormed (inputShape axis) (middleShape axis) (inner axis))
    (outerValid : ∀ axis, SliceShape.IsWellFormed (middleShape axis) (outputShape axis)
      (outer axis))
    (combinedValid : ∀ axis, SliceShape.IsWellFormed (inputShape axis) (outputShape axis)
      (combined axis))
    (starts : ∀ axis, (combined axis).start = (inner axis).start + (outer axis).start)
    (innerStride : ∀ axis, (inner axis).stride = 1)
    (outerStride : ∀ axis, (outer axis).stride = 1)
    (combinedStride : ∀ axis, (combined axis).stride = 1) :
    (fun index => input (IndexMaps.sliceIndex inner innerValid
      (IndexMaps.sliceIndex outer outerValid index))) =
      (fun index => input (IndexMaps.sliceIndex combined combinedValid index)) := by
  funext index
  apply congrArg input
  funext axis
  apply Fin.ext
  have a := IndexMaps.sliceIndex_val inner innerValid
    (IndexMaps.sliceIndex outer outerValid index) axis
  have b := IndexMaps.sliceIndex_val outer outerValid index axis
  have c := IndexMaps.sliceIndex_val combined combinedValid index axis
  rw [innerStride axis] at a
  rw [outerStride axis] at b
  rw [combinedStride axis, starts axis] at c
  simp at a b c
  omega

#print axioms nested_count
#print axioms nested
#print axioms full_shape
#print axioms full

end TensorRewrite.PaperComparison.SliceGeometry
