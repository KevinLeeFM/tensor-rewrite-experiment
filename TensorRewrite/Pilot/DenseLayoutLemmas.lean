module

public import TensorRewrite.Pilot.DenseLayout
public import TensorRewrite.Pilot.LinearIndexLemmas
public import TensorRewrite.Pilot.PermutationArrayLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.DenseLayout

/-- Logical coordinates survive physical ordering and inverse ordering. -/
theorem fromOrdered_toOrdered {rank : Nat} {shape : Shape rank} (layout : DenseLayout rank)
    (index : Index shape) : layout.fromOrderedIndex (layout.toOrderedIndex index) = index := by
  funext axis
  apply Fin.ext
  change (index (layout.minorToMajor.outputToInput
    (layout.minorToMajor.inputToOutput axis).rev.rev)).val = (index axis).val
  apply congrArg (fun coordinate => (index coordinate).val)
  rw [Fin.rev_rev, layout.minorToMajor.output_input]

/-- Physical coordinates survive inverse ordering and physical ordering. -/
theorem toOrdered_fromOrdered {rank : Nat} {shape : Shape rank} (layout : DenseLayout rank)
    (index : Index (layout.orderedShape shape)) :
    layout.toOrderedIndex (layout.fromOrderedIndex index) = index := by
  funext slot
  apply Fin.ext
  change (index (layout.minorToMajor.inputToOutput
    (layout.minorToMajor.outputToInput slot.rev)).rev).val = (index slot).val
  apply congrArg (fun coordinate => (index coordinate).val)
  rw [layout.minorToMajor.input_output, Fin.rev_rev]

/-- Encoding then observing preserves every logical value, including empty/scalar cases. -/
theorem read_write {rank : Nat} {shape : Shape rank} {α : Type} (layout : DenseLayout rank)
    (input : Tensor shape α) : layout.read (layout.write input) = input := by
  funext index
  unfold read write address
  rw [LinearIndex.delinearize_linearize, fromOrdered_toOrdered]

/-- Observing then encoding preserves every physical cell. -/
theorem write_read {rank : Nat} {shape : Shape rank} {α : Type} (layout : DenseLayout rank)
    (buffer : layout.Buffer shape α) : layout.write (layout.read buffer) = buffer := by
  funext position
  unfold read write address
  change buffer (LinearIndex.linearize (layout.orderedShape shape)
    (layout.toOrderedIndex (layout.fromOrderedIndex
      (LinearIndex.delinearize (layout.orderedShape shape) position)))) = buffer position
  rw [toOrdered_fromOrdered, LinearIndex.linearize_delinearize]

/-- The source's array equation gives the corresponding axis equation at every slot. -/
theorem minorOrderMatches_axis {rank : Nat} (permutation : AxisPermutation rank)
    (inputLayout outputLayout : DenseLayout rank)
    (compatible : MinorOrderMatches permutation inputLayout outputLayout) (slot : Fin rank) :
    inputLayout.minorToMajor.outputToInput slot =
      permutation.outputToInput (outputLayout.minorToMajor.outputToInput slot) := by
  have entry := congrArg (fun array : AxisArray rank => array[slot]) compatible
  simpa only [AxisArray.compose_get, AxisArray.ofPermutation_get] using entry.symm

/-- Component-wise physical-axis equality proves the finite source array equation. -/
theorem minorOrderMatches_of_axis {rank : Nat} (permutation : AxisPermutation rank)
    (inputLayout outputLayout : DenseLayout rank)
    (axes : ∀ slot, inputLayout.minorToMajor.outputToInput slot =
      permutation.outputToInput (outputLayout.minorToMajor.outputToInput slot)) :
    MinorOrderMatches permutation inputLayout outputLayout := by
  apply Vector.ext
  intro i hi
  have entry := axes ⟨i, hi⟩
  change (AxisArray.compose (AxisArray.ofPermutation permutation)
    (AxisArray.ofPermutation outputLayout.minorToMajor))[(⟨i, hi⟩ : Fin rank)] =
      (AxisArray.ofPermutation inputLayout.minorToMajor)[(⟨i, hi⟩ : Fin rank)]
  simpa only [AxisArray.compose_get, AxisArray.ofPermutation_get] using entry.symm

/-- Source output-to-input extent equations imply the inverse convention of logical transpose. -/
theorem transpose_extents {rank : Nat} {inputShape outputShape : Shape rank}
    (permutation : AxisPermutation rank)
    (extents : ∀ axis, outputShape axis = inputShape (permutation.outputToInput axis))
    (axis : Fin rank) : outputShape (permutation.inputToOutput axis) = inputShape axis :=
  (extents _).trans (congrArg inputShape (permutation.output_input axis))

/-- Matching physical axis order yields identical physically ordered shapes. -/
theorem orderedShape_transpose {rank : Nat} {inputShape outputShape : Shape rank}
    (permutation : AxisPermutation rank) (inputLayout outputLayout : DenseLayout rank)
    (extents : ∀ axis, outputShape axis = inputShape (permutation.outputToInput axis))
    (compatible : MinorOrderMatches permutation inputLayout outputLayout) :
    inputLayout.orderedShape inputShape = outputLayout.orderedShape outputShape := by
  funext slot
  change inputShape (inputLayout.minorToMajor.outputToInput slot.rev) = _
  rw [minorOrderMatches_axis permutation inputLayout outputLayout compatible]
  exact (extents _).symm

/-- Transporting equal shape bounds preserves the computed linear position. -/
theorem linearize_cast_val {rank : Nat} {left right : Shape rank} (sameShape : left = right)
    (index : Index right) :
    (LinearIndex.linearize left (fun axis =>
      Fin.cast (congrArg (fun shape => shape axis) sameShape.symm) (index axis))).val =
        (LinearIndex.linearize right index).val := by
  cases sameShape
  rfl

/-- Transpose and the matched output layout select the same physical cell address. -/
theorem address_transpose_val {rank : Nat} {inputShape outputShape : Shape rank}
    (permutation : AxisPermutation rank) (inputLayout outputLayout : DenseLayout rank)
    (extents : ∀ axis, outputShape axis = inputShape (permutation.outputToInput axis))
    (compatible : MinorOrderMatches permutation inputLayout outputLayout)
    (index : Index outputShape) :
    (inputLayout.address (Tensor.transposeIndex permutation
      (transpose_extents permutation extents) index)).val = (outputLayout.address index).val := by
  have shapes := orderedShape_transpose permutation inputLayout outputLayout extents compatible
  have coordinates : inputLayout.toOrderedIndex
      (Tensor.transposeIndex permutation (transpose_extents permutation extents) index) =
      fun slot => Fin.cast (congrArg (fun shape => shape slot) shapes.symm)
        (outputLayout.toOrderedIndex index slot) := by
    funext slot
    apply Fin.ext
    change (index (permutation.inputToOutput
      (inputLayout.minorToMajor.outputToInput slot.rev))).val =
        (index (outputLayout.minorToMajor.outputToInput slot.rev)).val
    apply congrArg (fun axis => (index axis).val)
    rw [minorOrderMatches_axis permutation inputLayout outputLayout compatible,
      permutation.input_output]
  unfold address
  rw [coordinates]
  exact linearize_cast_val shapes _

end TensorRewrite.Pilot.DenseLayout
