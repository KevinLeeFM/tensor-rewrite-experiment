module

public import TensorRewrite.Theory.ConvolutionDotLemmas
public import TensorRewrite.Theory.FiniteSum

/-! Exact pointwise convolution represented by the existing mathematical Dot model. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConvolutionDot

open Pilot Convolution ConvolutionPointwise

/-- The actual matrix Dot contracts precisely over the input-channel domain. -/
theorem dot_eq_channel_sum {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (unitKernel : ∀ axis, plan.kernelShape axis = 1)
    (input : Input plan α) (kernel : Kernel plan α)
    (batchGroup : Fin plan.batchGroups) (featureGroup : Fin plan.featureGroups)
    (output : Index (matrixPlan plan).outputShape) :
    Contraction.dotTensor (matrixPlan plan) (· + ·) 0 (· * ·) id
      (lhsMatrix plan input batchGroup featureGroup)
      (rhsMatrix plan unitKernel kernel batchGroup featureGroup) output =
      ∑ channel : Fin plan.inputFeaturesPerGroup,
        input (FiniteProduct.join batchGroup (FiniteProduct.row (output 0)))
            (FiniteProduct.join featureGroup channel)
            (LinearIndex.delinearize plan.inputShape (FiniteProduct.column (output 0))) *
          kernel batchGroup featureGroup (output 1) channel (kernelIndex plan unitKernel) := by
  simp only [Contraction.dotTensor, Contraction.terms, id_eq,
    FiniteSum.foldl_add_eq_sum, zero_add]
  rw [← Fin.sum_univ_def]
  simp only [lhsMatrix, rhsMatrix, lhs_index_row, lhs_index_channel,
    rhs_index_feature, rhs_index_channel]
  exact sum_contract_positions plan.inputFeaturesPerGroup (fun channel =>
    input (FiniteProduct.join batchGroup (FiniteProduct.row (output 0)))
        (FiniteProduct.join featureGroup channel)
        (LinearIndex.delinearize plan.inputShape (FiniteProduct.column (output 0))) *
      kernel batchGroup featureGroup (output 1) channel (kernelIndex plan unitKernel))

/-- Every output of an exact pointwise convolution equals its flattened matrix Dot value. -/
theorem convolve_eq_dot {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (pointwise : IsPointwise plan) (input : Input plan α) (kernel : Kernel plan α)
    (output : OutputIndex plan) :
    convolve plan input kernel output =
      Contraction.dotTensor (matrixPlan plan) (· + ·) 0 (· * ·) id
        (lhsMatrix plan input output.batchGroup output.featureGroup)
        (rhsMatrix plan (fun axis => (pointwise axis).unitKernel) kernel
          output.batchGroup output.featureGroup)
        (dotOutput plan (output_shape_eq plan pointwise) output) := by
  rw [convolve_eq_channelSum plan pointwise,
    dot_eq_channel_sum plan (fun axis => (pointwise axis).unitKernel) input kernel
      output.batchGroup output.featureGroup
      (dotOutput plan (output_shape_eq plan pointwise) output)]
  simp only [channelSum, dotOutput, matrix_output_row, matrix_output_feature,
    FiniteProduct.row_join, FiniteProduct.column_join, LinearIndex.delinearize_linearize]

/-- Every matrix result within an existing group pair corresponds to a convolution result. -/
theorem dot_eq_convolve {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (pointwise : IsPointwise plan) (input : Input plan α) (kernel : Kernel plan α)
    (batchGroup : Fin plan.batchGroups) (featureGroup : Fin plan.featureGroups)
    (output : Index (matrixPlan plan).outputShape) :
    Contraction.dotTensor (matrixPlan plan) (· + ·) 0 (· * ·) id
      (lhsMatrix plan input batchGroup featureGroup)
      (rhsMatrix plan (fun axis => (pointwise axis).unitKernel) kernel batchGroup featureGroup)
      output =
      convolve plan input kernel
        (convolutionOutput plan (output_shape_eq plan pointwise)
          batchGroup featureGroup output) := by
  rw [convolve_eq_dot plan pointwise, dot_output_convolution_output]
  rfl

end TensorRewrite.Theory.ConvolutionDot
