module

public import TensorRewrite.Pilot.DenseLayoutLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.DenseLayout

/-- A source-compatible transpose equals a same-cell bitcast in the untiled dense profile. -/
theorem transpose_eq_bitcast {rank : Nat} {inputShape outputShape : Shape rank} {α : Type}
    (permutation : AxisPermutation rank) (inputLayout outputLayout : DenseLayout rank)
    (extents : ∀ axis, outputShape axis = inputShape (permutation.outputToInput axis))
    (compatible : MinorOrderMatches permutation inputLayout outputLayout)
    (input : Tensor inputShape α) :
    Tensor.transpose permutation (transpose_extents permutation extents) input =
      bitcastTensor inputLayout outputLayout outputShape
        (congrArg LinearIndex.elementCount
          (orderedShape_transpose permutation inputLayout outputLayout extents compatible))
        input := by
  funext index
  have addressValue := address_transpose_val permutation inputLayout outputLayout
    extents compatible index
  let physicalPosition : Fin (LinearIndex.elementCount (inputLayout.orderedShape inputShape)) :=
    ⟨(outputLayout.address index).val, by
      rw [congrArg LinearIndex.elementCount
        (orderedShape_transpose permutation inputLayout outputLayout extents compatible)]
      exact (outputLayout.address index).isLt⟩
  have position : inputLayout.address (Tensor.transposeIndex permutation
      (transpose_extents permutation extents) index) = physicalPosition := Fin.ext addressValue
  change input (Tensor.transposeIndex permutation (transpose_extents permutation extents) index) =
    inputLayout.write input physicalPosition
  rw [← position]
  unfold write address
  rw [LinearIndex.delinearize_linearize, fromOrdered_toOrdered]

end TensorRewrite.Pilot.DenseLayout
