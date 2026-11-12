module

public import TensorRewrite.Theory.ConvolutionSeparableReindex

/-! Mixed pointwise/spanning convolution with arbitrary feature channels. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.MixedConvolution

open Pilot Theory Convolution ConvolutionSeparable

/-- Channels and complete spatial kernel coordinates enumerate all convolution terms. -/
def allPositionEquiv {rank : Nat} (plan : Plan rank) :
    (Fin plan.inputFeaturesPerGroup × Index plan.kernelShape) ≃
      Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape) where
  toFun pair := FiniteProduct.join pair.1 (LinearIndex.linearize plan.kernelShape pair.2)
  invFun position := (FiniteProduct.row position,
    LinearIndex.delinearize plan.kernelShape (FiniteProduct.column position))
  left_inv pair := by
    apply Prod.ext
    · simp [FiniteProduct.row_join]
    · simp [FiniteProduct.column_join, LinearIndex.delinearize_linearize]
  right_inv position := by
    simp [LinearIndex.linearize_delinearize, FiniteProduct.join_row_column]

/-- Channels and only nonunit spatial axes enumerate precisely the same term positions. -/
def reducedPositionEquivAll {rank : Nat} (plan : Plan rank) :
    (Fin plan.inputFeaturesPerGroup × ReducedIndex plan) ≃
      Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape) :=
  (Equiv.prodCongr (Equiv.refl _) ((reducedKernelEquiv plan).trans (reverseKernelEquiv plan))).trans
    (allPositionEquiv plan)

/-- Mixed-window product and reduction over every feature and nonunit spatial coordinate. -/
def productReductionAll {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (geometry : Geometry plan) (input : Input plan α) (kernel : Kernel plan α) :
    OutputIndex plan → α := fun output =>
  ∑ pair : Fin plan.inputFeaturesPerGroup × ReducedIndex plan,
    input (FiniteProduct.join output.batchGroup output.batch)
        (FiniteProduct.join output.featureGroup pair.1)
        (productInputIndex plan geometry output.spatial (expandKernel plan pair.2)) *
      kernel output.batchGroup output.featureGroup output.feature pair.1
        (reverseKernel plan (expandKernel plan pair.2))

/-- One reindexed contribution uses the paper's feature and spatial reduction coordinates. -/
theorem term_reduced_all {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (separable : IsSeparable plan) (input : Input plan α) (kernel : Kernel plan α)
    (output : OutputIndex plan) (pair : Fin plan.inputFeaturesPerGroup × ReducedIndex plan) :
    term plan input kernel output (reducedPositionEquivAll plan pair) =
      input (FiniteProduct.join output.batchGroup output.batch)
          (FiniteProduct.join output.featureGroup pair.1)
          (productInputIndex plan (derive_geometry plan separable) output.spatial
            (expandKernel plan pair.2)) *
        kernel output.batchGroup output.featureGroup output.feature pair.1
          (reverseKernel plan (expandKernel plan pair.2)) := by
  change term plan input kernel output
    (FiniteProduct.join pair.1 (LinearIndex.linearize plan.kernelShape
      (reverseKernel plan (expandKernel plan pair.2)))) = _
  dsimp only [term]
  rw [FiniteProduct.row_join, FiniteProduct.column_join, LinearIndex.delinearize_linearize,
    spatial_input_eq plan separable, reverse_involution]

/-- `conv/rule03`: mixed windows reduce over all features and nonunit spatial groups. -/
theorem mixed_product {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (separable : IsSeparable plan) (input : Input plan α) (kernel : Kernel plan α) :
    convolve plan input kernel =
      productReductionAll plan (derive_geometry plan separable) input kernel := by
  funext output
  unfold convolve productReductionAll
  rw [← Fin.sum_univ_def,
    ← Equiv.sum_comp (reducedPositionEquivAll plan) (term plan input kernel output)]
  apply Finset.sum_congr rfl
  intro pair _
  exact term_reduced_all plan separable input kernel output pair

/-- The paper's equal input/kernel spatial axis has exactly one output coordinate. -/
theorem spanning_output_one (axis : Axis)
    (unitStride : axis.stride = 1) (unitBase : axis.baseDilation = 1)
    (unitKernel : axis.kernelDilation = 1) (low : axis.paddingLow = 0)
    (high : axis.paddingHigh = 0) (equalExtent : axis.inputExtent = axis.kernelExtent) :
    axis.outputExtent = 1 := by
  unfold Axis.outputExtent
  rw [unitStride, unitBase, unitKernel, low, high, equalExtent]
  simp

/-- The two paper spatial-axis choices imply the general mixed-window condition. -/
theorem paper_axis_separable (axis : Axis)
    (unitStride : axis.stride = 1) (unitBase : axis.baseDilation = 1)
    (unitKernel : axis.kernelDilation = 1) (low : axis.paddingLow = 0)
    (high : axis.paddingHigh = 0)
    (paperAxis : axis.kernelExtent = 1 ∨ axis.inputExtent = axis.kernelExtent) :
    IsSeparableAxis axis := by
  refine ⟨unitStride, unitBase, unitKernel, low, high, ?_⟩
  rcases paperAxis with unit | spanning
  · exact Or.inl unit
  · exact Or.inr (spanning_output_one axis unitStride unitBase unitKernel low high spanning)

/-- Dot's two contraction groups are the feature group and the nonunit spatial group. -/
theorem dot_grouping {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (geometry : Geometry plan) (input : Input plan α) (kernel : Kernel plan α) :
    productReductionAll plan geometry input kernel = fun output =>
      ∑ channel : Fin plan.inputFeaturesPerGroup, ∑ spatial : ReducedIndex plan,
        input (FiniteProduct.join output.batchGroup output.batch)
            (FiniteProduct.join output.featureGroup channel)
            (productInputIndex plan geometry output.spatial (expandKernel plan spatial)) *
          kernel output.batchGroup output.featureGroup output.feature channel
            (reverseKernel plan (expandKernel plan spatial)) := by
  funext output
  exact Fintype.sum_prod_type _

/-- The mixed convolution is the grouped Dot reduction at every bounded output coordinate. -/
theorem conv_to_grouped_dot {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (separable : IsSeparable plan) (input : Input plan α) (kernel : Kernel plan α) :
    convolve plan input kernel = fun output =>
      ∑ channel : Fin plan.inputFeaturesPerGroup, ∑ spatial : ReducedIndex plan,
        input (FiniteProduct.join output.batchGroup output.batch)
            (FiniteProduct.join output.featureGroup channel)
            (productInputIndex plan (derive_geometry plan separable) output.spatial
              (expandKernel plan spatial)) *
          kernel output.batchGroup output.featureGroup output.feature channel
            (reverseKernel plan (expandKernel plan spatial)) := by
  rw [mixed_product plan separable input kernel, dot_grouping]

#print axioms paper_axis_separable
#print axioms dot_grouping
#print axioms conv_to_grouped_dot
#print axioms term_reduced_all
#print axioms mixed_product
#print axioms spanning_output_one

end TensorRewrite.PaperComparison.MixedConvolution
