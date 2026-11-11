module

public import TensorRewrite.Theory.ConvolutionOrderedLemmas

/-! Pointwise convolution-to-Dot preserves arbitrary ordered scalar computations. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConvolutionOrdered

open Pilot ConvolutionPointwise ConvolutionDot

/-- The pointwise matrix rewrite preserves the fold, initializer, product and finish exactly.
No associativity, distributivity, commutativity or scalar identity law is assumed. -/
theorem convolve_eq_dot {rank : Nat} {L R Acc Result : Type} (plan : Convolution.Plan rank)
    (pointwise : IsPointwise plan) (add : Acc → Acc → Acc) (initial padding : Acc)
    (multiply : L → R → Acc) (finish : Acc → Result)
    (input : Convolution.Input plan L) (kernel : Convolution.Kernel plan R)
    (output : Convolution.OutputIndex plan) :
    convolve plan add initial padding multiply finish input kernel output =
      Contraction.dotTensor (matrixPlan plan) add initial multiply finish
        (lhsMatrix plan input output.batchGroup output.featureGroup)
        (rhsMatrix plan (fun axis => (pointwise axis).unitKernel) kernel
          output.batchGroup output.featureGroup)
        (dotOutput plan (output_shape_eq plan pointwise) output) := by
  simp only [convolve, Contraction.dotTensor, terms_eq_dot_terms plan pointwise]

/-- The inverse matrix-coordinate direction preserves the same ordered computation. -/
theorem dot_eq_convolve {rank : Nat} {L R Acc Result : Type} (plan : Convolution.Plan rank)
    (pointwise : IsPointwise plan) (add : Acc → Acc → Acc) (initial padding : Acc)
    (multiply : L → R → Acc) (finish : Acc → Result)
    (input : Convolution.Input plan L) (kernel : Convolution.Kernel plan R)
    (batchGroup : Fin plan.batchGroups) (featureGroup : Fin plan.featureGroups)
    (output : Index (matrixPlan plan).outputShape) :
    Contraction.dotTensor (matrixPlan plan) add initial multiply finish
      (lhsMatrix plan input batchGroup featureGroup)
      (rhsMatrix plan (fun axis => (pointwise axis).unitKernel) kernel batchGroup featureGroup)
      output = convolve plan add initial padding multiply finish input kernel
        (convolutionOutput plan (output_shape_eq plan pointwise)
          batchGroup featureGroup output) := by
  rw [convolve_eq_dot plan pointwise, dot_output_convolution_output]
  rfl

/-- A single-channel pointwise convolution retains its initial accumulation and finish.
Discarding either operation requires additional scalar laws. -/
theorem convolve_single_channel {rank : Nat} {L R Acc Result : Type}
    (plan : Convolution.Plan rank) (pointwise : IsPointwise plan)
    (single : plan.inputFeaturesPerGroup = 1) (add : Acc → Acc → Acc) (initial padding : Acc)
    (multiply : L → R → Acc) (finish : Acc → Result)
    (input : Convolution.Input plan L) (kernel : Convolution.Kernel plan R)
    (output : Convolution.OutputIndex plan) :
    convolve plan add initial padding multiply finish input kernel output =
      finish (add initial (multiply
        (input (FiniteProduct.join output.batchGroup output.batch)
          (FiniteProduct.join output.featureGroup ⟨0, by omega⟩)
          (inputIndex plan (output_shape_eq plan pointwise) output.spatial))
        (kernel output.batchGroup output.featureGroup output.feature ⟨0, by omega⟩
          (kernelIndex plan (fun axis => (pointwise axis).unitKernel))))) := by
  have count : plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape = 1 := by
    rw [single, kernel_count_eq_one plan pointwise]
  unfold convolve terms
  rw [map_finRange_singleton count]
  simp only [List.foldl_cons, List.foldl_nil]
  rw [term_pointwise plan pointwise]
  simp only [FiniteProduct.row, Nat.zero_div]

end TensorRewrite.Theory.ConvolutionOrdered
