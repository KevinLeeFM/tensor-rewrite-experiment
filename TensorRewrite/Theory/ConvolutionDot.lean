module

public import TensorRewrite.Theory.ConvolutionPointwiseAlgebra
public import TensorRewrite.Pilot.Contraction

/-! A logical matrix representation of each pointwise-convolution group pair.
Rows combine batches and spatial coordinates; columns are output features. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConvolutionDot

open Pilot Convolution ConvolutionPointwise

/-- Number of matrix rows, including the spatial scalar case and zero extents. -/
def rowCount {rank : Nat} (plan : Plan rank) : Nat :=
  plan.batchesPerGroup * LinearIndex.elementCount plan.inputShape

/-- An actual contraction plan with one row axis, one output-feature axis and one channel axis. -/
def matrixPlan {rank : Nat} (plan : Plan rank) : Contraction.Plan 0 1 1 1 := {
  batchShape := Fin.elim0
  leftShape := fun _ => rowCount plan
  rightShape := fun _ => plan.outputFeaturesPerGroup
  contractShape := fun _ => plan.inputFeaturesPerGroup
  leftOrder := AxisPermutation.identity 2
  rightOrder := AxisPermutation.identity 2
}

/-- Input matrix, unflattening each row into a bounded batch and spatial input coordinate. -/
def lhsMatrix {rank : Nat} {α : Type} (plan : Plan rank) (input : Input plan α)
    (batchGroup : Fin plan.batchGroups) (featureGroup : Fin plan.featureGroups) :
    Tensor (matrixPlan plan).lhsShape α :=
  fun index => input (FiniteProduct.join batchGroup (FiniteProduct.row (index 0)))
    (FiniteProduct.join featureGroup (index 1))
    (LinearIndex.delinearize plan.inputShape (FiniteProduct.column (index 0)))

/-- Kernel matrix with output-feature rows and input-channel columns.
Dot contracts its second axis with the input matrix's second axis. -/
def rhsMatrix {rank : Nat} {α : Type} (plan : Plan rank)
    (unitKernel : ∀ axis, plan.kernelShape axis = 1) (kernel : Kernel plan α)
    (batchGroup : Fin plan.batchGroups) (featureGroup : Fin plan.featureGroups) :
    Tensor (matrixPlan plan).rhsShape α :=
  fun index => kernel batchGroup featureGroup (index 0) (index 1) (kernelIndex plan unitKernel)

/-- Encode a batch/spatial coordinate and output feature as a matrix result coordinate. -/
def matrixOutput {rank : Nat} (plan : Plan rank) (batch : Fin plan.batchesPerGroup)
    (spatial : Index plan.inputShape) (feature : Fin plan.outputFeaturesPerGroup) :
    Index (matrixPlan plan).outputShape :=
  Contraction.appendIndex (fun axis => Fin.elim0 axis)
    (Contraction.appendIndex
      (fun _ => FiniteProduct.join batch (LinearIndex.linearize plan.inputShape spatial))
      (fun _ => feature))

/-- Flatten a convolution output within its group pair, using the proved spatial shape equality. -/
def dotOutput {rank : Nat} (plan : Plan rank) (sameShape : plan.outputShape = plan.inputShape)
    (output : OutputIndex plan) : Index (matrixPlan plan).outputShape :=
  matrixOutput plan output.batch (inputIndex plan sameShape output.spatial) output.feature

/-- Recover a convolution output from a matrix result within a fixed group pair. -/
def convolutionOutput {rank : Nat} (plan : Plan rank)
    (sameShape : plan.outputShape = plan.inputShape)
    (batchGroup : Fin plan.batchGroups) (featureGroup : Fin plan.featureGroups)
    (index : Index (matrixPlan plan).outputShape) : OutputIndex plan := {
  batch := FiniteProduct.row (index 0)
  batchGroup := batchGroup
  featureGroup := featureGroup
  feature := index 1
  spatial := fun axis => Fin.cast (congrFun sameShape axis).symm
    (LinearIndex.delinearize plan.inputShape (FiniteProduct.column (index 0)) axis)
}

end TensorRewrite.Theory.ConvolutionDot
