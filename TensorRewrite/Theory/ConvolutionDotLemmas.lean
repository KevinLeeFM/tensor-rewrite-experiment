module

public import Mathlib.Tactic.FinCases
public import TensorRewrite.Theory.ConvolutionDot
public import TensorRewrite.Pilot.ContractionLemmas
public import TensorRewrite.Pilot.FiniteProductLemmas

/-! Bounded coordinate recovery for pointwise convolution's logical matrices. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConvolutionDot

open Pilot Convolution ConvolutionPointwise

/-- The lhs contraction keeps the output matrix row. -/
theorem lhs_index_row {rank : Nat} (plan : Plan rank)
    (output : Index (matrixPlan plan).outputShape)
    (contract : Index (matrixPlan plan).contractShape) :
    (matrixPlan plan).lhsIndex output contract 0 = output 0 := by
  apply Fin.ext
  rfl

/-- The lhs contraction reads the selected input channel. -/
theorem lhs_index_channel {rank : Nat} (plan : Plan rank)
    (output : Index (matrixPlan plan).outputShape)
    (contract : Index (matrixPlan plan).contractShape) :
    (matrixPlan plan).lhsIndex output contract 1 = contract 0 := by
  apply Fin.ext
  rfl

/-- The rhs contraction keeps the output feature. -/
theorem rhs_index_feature {rank : Nat} (plan : Plan rank)
    (output : Index (matrixPlan plan).outputShape)
    (contract : Index (matrixPlan plan).contractShape) :
    (matrixPlan plan).rhsIndex output contract 0 = output 1 := by
  apply Fin.ext
  rfl

/-- The rhs contraction reads the same input channel as the lhs. -/
theorem rhs_index_channel {rank : Nat} (plan : Plan rank)
    (output : Index (matrixPlan plan).outputShape)
    (contract : Index (matrixPlan plan).contractShape) :
    (matrixPlan plan).rhsIndex output contract 1 = contract 0 := by
  apply Fin.ext
  rfl

/-- Matrix row encoding packs batch and linear spatial coordinates. -/
theorem matrix_output_row {rank : Nat} (plan : Plan rank) (batch : Fin plan.batchesPerGroup)
    (spatial : Index plan.inputShape) (feature : Fin plan.outputFeaturesPerGroup) :
    matrixOutput plan batch spatial feature 0 =
      FiniteProduct.join batch (LinearIndex.linearize plan.inputShape spatial) := by
  apply Fin.ext
  rfl

/-- Matrix column encoding keeps the output feature. -/
theorem matrix_output_feature {rank : Nat} (plan : Plan rank)
    (batch : Fin plan.batchesPerGroup) (spatial : Index plan.inputShape)
    (feature : Fin plan.outputFeaturesPerGroup) :
    matrixOutput plan batch spatial feature 1 = feature := by
  apply Fin.ext
  rfl

/-- Decoding an encoded convolution result recovers every output field. -/
theorem convolution_output_dot_output {rank : Nat} (plan : Plan rank)
    (sameShape : plan.outputShape = plan.inputShape) (output : OutputIndex plan) :
    convolutionOutput plan sameShape output.batchGroup output.featureGroup
      (dotOutput plan sameShape output) = output := by
  cases output
  simp only [dotOutput, convolutionOutput, matrix_output_row, matrix_output_feature,
    FiniteProduct.row_join, FiniteProduct.column_join, LinearIndex.delinearize_linearize]
  congr 1

/-- Encoding a decoded matrix coordinate recovers the whole coordinate. -/
theorem dot_output_convolution_output {rank : Nat} (plan : Plan rank)
    (sameShape : plan.outputShape = plan.inputShape)
    (batchGroup : Fin plan.batchGroups) (featureGroup : Fin plan.featureGroups)
    (index : Index (matrixPlan plan).outputShape) :
    dotOutput plan sameShape (convolutionOutput plan sameShape batchGroup featureGroup index) =
      index := by
  have spatial : inputIndex plan sameShape
      (convolutionOutput plan sameShape batchGroup featureGroup index).spatial =
      LinearIndex.delinearize plan.inputShape (FiniteProduct.column (index 0)) := by
    funext axis
    apply Fin.ext
    rfl
  unfold dotOutput
  rw [spatial]
  funext axis
  fin_cases axis
  · let row : Fin (plan.batchesPerGroup * LinearIndex.elementCount plan.inputShape) := index 0
    have recovered : matrixOutput plan (FiniteProduct.row row)
        (LinearIndex.delinearize plan.inputShape (FiniteProduct.column row)) (index 1) 0 = row := by
      have encoded := matrix_output_row plan (FiniteProduct.row row)
        (LinearIndex.delinearize plan.inputShape (FiniteProduct.column row)) (index 1)
      apply encoded.trans
      rw [LinearIndex.linearize_delinearize]
      exact FiniteProduct.join_row_column row
    exact recovered
  · exact matrix_output_feature plan _ _ _

/-- The one-axis contraction enumeration is equivalent to its channel domain. -/
theorem sum_contract_positions {α : Type} [AddCommMonoid α] (channels : Nat)
    (value : Fin channels → α) :
    (∑ position : Fin (channels * 1), value (FiniteProduct.row position)) =
      ∑ channel, value channel := by
  have row_eq (position : Fin (channels * 1)) :
      FiniteProduct.row position = finCongr (Nat.mul_one channels) position := by
    apply Fin.ext
    change position.val / 1 = position.val
    exact Nat.div_one _
  calc
    _ = ∑ position, value (finCongr (Nat.mul_one channels) position) := by
      apply Finset.sum_congr rfl
      intro position _
      rw [row_eq]
    _ = _ := Equiv.sum_comp (finCongr (Nat.mul_one channels)) value

end TensorRewrite.Theory.ConvolutionDot
