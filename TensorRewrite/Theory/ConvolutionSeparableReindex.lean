module

public import TensorRewrite.Theory.ConvolutionSeparableLemmas
public import TensorRewrite.Pilot.FiniteProductLemmas

/-! Equivalences remove unit axes and the sole channel, and move reversal onto the kernel. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConvolutionSeparable

open Pilot Convolution

/-- Projecting after expansion preserves every retained reduction coordinate. -/
theorem project_expand {rank : Nat} (plan : Plan rank) (index : ReducedIndex plan) :
    projectKernel plan (expandKernel plan index) = index := by
  funext axis
  simp [projectKernel, expandKernel, axis.property]

/-- Expanding a projection recovers a full kernel coordinate, including all unit axes. -/
theorem expand_project {rank : Nat} (plan : Plan rank) (index : Index plan.kernelShape) :
    expandKernel plan (projectKernel plan index) = index := by
  funext axis
  dsimp only [expandKernel]
  split
  next unit =>
    apply Fin.ext
    have bound := (index axis).isLt
    change 0 = (index axis).val
    omega
  next notUnit => rfl

/-- Reversing the same selected axes twice recovers every kernel coordinate. -/
theorem reverse_involution {rank : Nat} (plan : Plan rank) (index : Index plan.kernelShape) :
    reverseKernel plan (reverseKernel plan index) = index := by
  funext axis
  cases reversed : (plan.window axis).reversed <;> simp [reverseKernel, reversed]

/-- The reduced domain and full kernel coordinates are equivalent. -/
def reducedKernelEquiv {rank : Nat} (plan : Plan rank) :
    ReducedIndex plan ≃ Index plan.kernelShape where
  toFun := expandKernel plan
  invFun := projectKernel plan
  left_inv := project_expand plan
  right_inv := expand_project plan

/-- Selected-axis reversal is an equivalence, not an assumed sum invariant. -/
def reverseKernelEquiv {rank : Nat} (plan : Plan rank) :
    Index plan.kernelShape ≃ Index plan.kernelShape where
  toFun := reverseKernel plan
  invFun := reverseKernel plan
  left_inv := reverse_involution plan
  right_inv := reverse_involution plan

/-- With one input channel, kernel coordinates enumerate exactly the original contributions. -/
def positionEquiv {rank : Nat} (plan : Plan rank) (single : plan.inputFeaturesPerGroup = 1) :
    Index plan.kernelShape ≃
      Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape) where
  toFun := fun index => FiniteProduct.join (channelZero plan single)
    (LinearIndex.linearize plan.kernelShape index)
  invFun := fun position => LinearIndex.delinearize plan.kernelShape (FiniteProduct.column position)
  left_inv := by
    intro index
    dsimp only
    rw [FiniteProduct.column_join, LinearIndex.delinearize_linearize]
  right_inv := by
    intro position
    dsimp only
    have row_eq : FiniteProduct.row position = channelZero plan single := by
      apply Fin.ext
      have bound := (FiniteProduct.row position).isLt
      change (FiniteProduct.row position).val = 0
      omega
    rw [LinearIndex.linearize_delinearize, ← row_eq, FiniteProduct.join_row_column]

/-- The reduced product domain covers the complete original convolution contribution domain. -/
def reducedPositionEquiv {rank : Nat} (plan : Plan rank)
    (single : plan.inputFeaturesPerGroup = 1) : ReducedIndex plan ≃
      Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape) :=
  (reducedKernelEquiv plan).trans ((reverseKernelEquiv plan).trans (positionEquiv plan single))

/-- The equivalence inserts unit axes, reverses the kernel and inserts the sole channel. -/
theorem reduced_position_apply {rank : Nat} (plan : Plan rank)
    (single : plan.inputFeaturesPerGroup = 1) (reduced : ReducedIndex plan) :
    reducedPositionEquiv plan single reduced =
      FiniteProduct.join (channelZero plan single) (LinearIndex.linearize plan.kernelShape
        (reverseKernel plan (expandKernel plan reduced))) := rfl

end TensorRewrite.Theory.ConvolutionSeparable
