module

public import TensorRewrite.Theory.ConvolutionOrdered
public import TensorRewrite.Theory.FiniteSum

/-! Ordered list equality connects pointwise convolution and the existing Dot schedule. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConvolutionOrdered

open Pilot ConvolutionPointwise ConvolutionDot

/-- Casting the bound of a finite range preserves its list order exactly. -/
theorem map_finRange_cast {α : Type} {first second : Nat} (same : first = second)
    (value : Fin second → α) :
    (List.finRange first).map (fun position => value (Fin.cast same position)) =
      (List.finRange second).map value := by
  cases same
  rfl

/-- A one-position contribution range is a singleton list, with no folding law assumed. -/
theorem map_finRange_singleton {α : Type} {count : Nat} (single : count = 1)
    (value : Fin count → α) :
    (List.finRange count).map value = [value ⟨0, by omega⟩] := by
  subst count
  rfl

/-- The ordered model specializes to the existing exact-semiring model. -/
theorem convolve_semiring {rank : Nat} {α : Type} [Semiring α] (plan : Convolution.Plan rank)
    (input : Convolution.Input plan α) (kernel : Convolution.Kernel plan α) :
    convolve plan (· + ·) 0 0 (· * ·) id input kernel = Convolution.convolve plan input kernel := by
  funext output
  have contribution : term plan 0 (· * ·) input kernel output =
      Convolution.term plan input kernel output := by
    funext position
    rfl
  simp only [convolve, terms, id_eq, FiniteSum.foldl_add_eq_sum, zero_add,
    Convolution.convolve, contribution]

/-- Pointwise contributions need no algebraic law and never observe the padding contribution. -/
theorem term_pointwise {rank : Nat} {L R Acc : Type} (plan : Convolution.Plan rank)
    (pointwise : IsPointwise plan) (padding : Acc) (multiply : L → R → Acc)
    (input : Convolution.Input plan L) (kernel : Convolution.Kernel plan R)
    (output : Convolution.OutputIndex plan)
    (position : Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape)) :
    term plan padding multiply input kernel output position =
      multiply (input (FiniteProduct.join output.batchGroup output.batch)
        (FiniteProduct.join output.featureGroup (FiniteProduct.row position))
        (inputIndex plan (output_shape_eq plan pointwise) output.spatial))
        (kernel output.batchGroup output.featureGroup output.feature (FiniteProduct.row position)
          (kernelIndex plan (fun axis => (pointwise axis).unitKernel))) := by
  dsimp only [term]
  rw [spatial_input_eq plan pointwise]
  rw [kernel_index_unique plan (fun axis => (pointwise axis).unitKernel)
    (LinearIndex.delinearize plan.kernelShape (FiniteProduct.column position))]

/-- Pointwise convolution and the one-axis matrix contraction have equal contribution counts. -/
theorem contribution_count_eq {rank : Nat} (plan : Convolution.Plan rank)
    (pointwise : IsPointwise plan) :
    plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape =
      LinearIndex.elementCount (matrixPlan plan).contractShape := by
  simp [matrixPlan, LinearIndex.elementCount, kernel_count_eq_one plan pointwise]

/-- Casting a scheduled position preserves its input-channel coordinate. -/
theorem channel_position_eq {rank : Nat} (plan : Convolution.Plan rank)
    (pointwise : IsPointwise plan)
    (position : Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape)) :
    FiniteProduct.row position =
      LinearIndex.delinearize (matrixPlan plan).contractShape
        (Fin.cast (contribution_count_eq plan pointwise) position) 0 := by
  apply Fin.ext
  change position.val / LinearIndex.elementCount plan.kernelShape = position.val / 1
  exact congrArg (fun count : Nat => position.val / count) (kernel_count_eq_one plan pointwise)

/-- A convolution contribution is the identical product at the same Dot schedule position. -/
theorem term_eq_dot_product {rank : Nat} {L R Acc : Type} (plan : Convolution.Plan rank)
    (pointwise : IsPointwise plan) (padding : Acc) (multiply : L → R → Acc)
    (input : Convolution.Input plan L) (kernel : Convolution.Kernel plan R)
    (output : Convolution.OutputIndex plan)
    (position : Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape)) :
    term plan padding multiply input kernel output position =
      multiply
        (lhsMatrix plan input output.batchGroup output.featureGroup
          ((matrixPlan plan).lhsIndex (dotOutput plan (output_shape_eq plan pointwise) output)
            (LinearIndex.delinearize (matrixPlan plan).contractShape
              (Fin.cast (contribution_count_eq plan pointwise) position))))
        (rhsMatrix plan (fun axis => (pointwise axis).unitKernel) kernel
          output.batchGroup output.featureGroup
          ((matrixPlan plan).rhsIndex (dotOutput plan (output_shape_eq plan pointwise) output)
            (LinearIndex.delinearize (matrixPlan plan).contractShape
              (Fin.cast (contribution_count_eq plan pointwise) position)))) := by
  rw [term_pointwise plan pointwise]
  simp only [lhsMatrix, rhsMatrix, lhs_index_row, lhs_index_channel,
    rhs_index_feature, rhs_index_channel, dotOutput, matrix_output_row, matrix_output_feature,
    FiniteProduct.row_join, FiniteProduct.column_join, LinearIndex.delinearize_linearize]
  rw [channel_position_eq plan pointwise]

/-- Pointwise convolution and matrix Dot have equal ordered contribution lists. -/
theorem terms_eq_dot_terms {rank : Nat} {L R Acc : Type} (plan : Convolution.Plan rank)
    (pointwise : IsPointwise plan) (padding : Acc) (multiply : L → R → Acc)
    (input : Convolution.Input plan L) (kernel : Convolution.Kernel plan R)
    (output : Convolution.OutputIndex plan) :
    terms plan padding multiply input kernel output =
      Contraction.terms (matrixPlan plan) multiply
        (lhsMatrix plan input output.batchGroup output.featureGroup)
        (rhsMatrix plan (fun axis => (pointwise axis).unitKernel) kernel
          output.batchGroup output.featureGroup)
        (dotOutput plan (output_shape_eq plan pointwise) output) := by
  let value := fun position : Fin (LinearIndex.elementCount (matrixPlan plan).contractShape) =>
    multiply
      (lhsMatrix plan input output.batchGroup output.featureGroup
        ((matrixPlan plan).lhsIndex (dotOutput plan (output_shape_eq plan pointwise) output)
          (LinearIndex.delinearize (matrixPlan plan).contractShape position)))
      (rhsMatrix plan (fun axis => (pointwise axis).unitKernel) kernel
        output.batchGroup output.featureGroup
        ((matrixPlan plan).rhsIndex (dotOutput plan (output_shape_eq plan pointwise) output)
          (LinearIndex.delinearize (matrixPlan plan).contractShape position)))
  have values : term plan padding multiply input kernel output =
      fun position => value (Fin.cast (contribution_count_eq plan pointwise) position) := by
    funext position
    exact term_eq_dot_product plan pointwise padding multiply input kernel output position
  unfold terms Contraction.terms
  rw [values]
  exact map_finRange_cast (contribution_count_eq plan pointwise) value

end TensorRewrite.Theory.ConvolutionOrdered
