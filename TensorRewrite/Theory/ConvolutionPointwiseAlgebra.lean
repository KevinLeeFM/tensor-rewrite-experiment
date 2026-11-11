module

public import TensorRewrite.Theory.ConvolutionPointwiseLemmas

/-! Eliminate the spatial kernel loop of an exact pointwise convolution. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConvolutionPointwise

open Pilot Convolution

/-- Each pointwise contribution samples the output location and the sole kernel coordinate. -/
theorem term_pointwise {rank : Nat} {α : Type} [Mul α] [Zero α] (plan : Plan rank)
    (pointwise : IsPointwise plan) (input : Input plan α) (kernel : Kernel plan α)
    (output : OutputIndex plan)
    (position : Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape)) :
    term plan input kernel output position =
      input (FiniteProduct.join output.batchGroup output.batch)
          (FiniteProduct.join output.featureGroup (FiniteProduct.row position))
          (inputIndex plan (output_shape_eq plan pointwise) output.spatial) *
        kernel output.batchGroup output.featureGroup output.feature (FiniteProduct.row position)
          (kernelIndex plan (fun axis => (pointwise axis).unitKernel)) := by
  dsimp only [term]
  rw [spatial_input_eq plan pointwise]
  rw [kernel_index_unique plan (fun axis => (pointwise axis).unitKernel)
    (LinearIndex.delinearize plan.kernelShape (FiniteProduct.column position))]

/-- Reindex the original channel/window loop to the actual channel domain. -/
theorem sum_kernel_positions {rank : Nat} {α : Type} [AddCommMonoid α] (plan : Plan rank)
    (pointwise : IsPointwise plan) (value : Fin plan.inputFeaturesPerGroup → α) :
    (∑ position : Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape),
      value (FiniteProduct.row position)) = ∑ channel, value channel := by
  let equivalence :
      Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape) ≃
        Fin plan.inputFeaturesPerGroup :=
    finCongr (by rw [kernel_count_eq_one plan pointwise, Nat.mul_one])
  have row_eq (position :
      Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape)) :
      FiniteProduct.row position = equivalence position := by
    apply Fin.ext
    simp [FiniteProduct.row, equivalence, kernel_count_eq_one plan pointwise]
  calc
    _ = ∑ position, value (equivalence position) := by
      apply Finset.sum_congr rfl
      intro position _
      rw [row_eq]
    _ = _ := Equiv.sum_comp equivalence value

/-- A pointwise convolution is a channel-only reduction at each output coordinate.
Ranks, extents, groups and channel counts are arbitrary, including empty domains. -/
theorem convolve_eq_channelSum {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (pointwise : IsPointwise plan) (input : Input plan α) (kernel : Kernel plan α) :
    convolve plan input kernel =
      channelSum plan (output_shape_eq plan pointwise)
        (fun axis => (pointwise axis).unitKernel) input kernel := by
  funext output
  unfold convolve channelSum
  rw [← Fin.sum_univ_def]
  simp_rw [term_pointwise plan pointwise]
  exact sum_kernel_positions plan pointwise (fun channel =>
    input (FiniteProduct.join output.batchGroup output.batch)
        (FiniteProduct.join output.featureGroup channel)
        (inputIndex plan (output_shape_eq plan pointwise) output.spatial) *
      kernel output.batchGroup output.featureGroup output.feature channel
        (kernelIndex plan (fun axis => (pointwise axis).unitKernel)))

/-- With one input channel per group, the pointwise channel sum is a single product. -/
theorem convolve_single_channel {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (pointwise : IsPointwise plan) (single : plan.inputFeaturesPerGroup = 1)
    (input : Input plan α) (kernel : Kernel plan α) (output : OutputIndex plan) :
    convolve plan input kernel output =
      input (FiniteProduct.join output.batchGroup output.batch)
          (FiniteProduct.join output.featureGroup ⟨0, by omega⟩)
          (inputIndex plan (output_shape_eq plan pointwise) output.spatial) *
        kernel output.batchGroup output.featureGroup output.feature ⟨0, by omega⟩
          (kernelIndex plan (fun axis => (pointwise axis).unitKernel)) := by
  rw [convolve_eq_channelSum plan pointwise]
  unfold channelSum
  rw [← Equiv.sum_comp (finCongr single.symm), Fin.sum_univ_one]
  rfl

end TensorRewrite.Theory.ConvolutionPointwise
