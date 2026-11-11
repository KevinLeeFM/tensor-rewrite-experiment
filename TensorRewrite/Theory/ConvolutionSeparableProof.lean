module

public import TensorRewrite.Theory.ConvolutionSeparableReindex

/-! Exact mixed-window convolution as broadcast/product and reduction of nonunit kernel axes. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConvolutionSeparable

open Pilot Convolution

/-- Reindexed contributions multiply an un-reversed input coordinate by a reversed kernel value. -/
theorem term_reduced {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (separable : IsSeparable plan) (single : plan.inputFeaturesPerGroup = 1)
    (input : Input plan α) (kernel : Kernel plan α) (output : OutputIndex plan)
    (reduced : ReducedIndex plan) :
    term plan input kernel output (reducedPositionEquiv plan single reduced) =
      input (FiniteProduct.join output.batchGroup output.batch)
          (FiniteProduct.join output.featureGroup (channelZero plan single))
          (productInputIndex plan (derive_geometry plan separable) output.spatial
            (expandKernel plan reduced)) *
        kernel output.batchGroup output.featureGroup output.feature (channelZero plan single)
          (reverseKernel plan (expandKernel plan reduced)) := by
  change term plan input kernel output
    (FiniteProduct.join (channelZero plan single) (LinearIndex.linearize plan.kernelShape
      (reverseKernel plan (expandKernel plan reduced)))) = _
  dsimp only [term]
  rw [FiniteProduct.row_join, FiniteProduct.column_join, LinearIndex.delinearize_linearize,
    spatial_input_eq plan separable, reverse_involution]

/-- Unit-kernel/spanning mixed windows become elementwise products and a reduction only over
nonunit kernel axes. This includes reversal, empty reductions and zero spatial rank. -/
theorem convolve_eq_productReduction {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (separable : IsSeparable plan) (single : plan.inputFeaturesPerGroup = 1)
    (input : Input plan α) (kernel : Kernel plan α) :
    convolve plan input kernel =
      productReduction plan (derive_geometry plan separable) single input kernel := by
  funext output
  unfold convolve productReduction
  rw [← Fin.sum_univ_def,
    ← Equiv.sum_comp (reducedPositionEquiv plan single) (term plan input kernel output)]
  apply Finset.sum_congr rfl
  intro reduced _
  exact term_reduced plan separable single input kernel output reduced

end TensorRewrite.Theory.ConvolutionSeparable
