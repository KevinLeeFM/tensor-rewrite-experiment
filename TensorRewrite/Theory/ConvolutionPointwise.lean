module

public import Mathlib.Algebra.BigOperators.Fin
public import TensorRewrite.Theory.Convolution

/-! Explicit conditions and a channel-only target for pointwise convolution. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConvolutionPointwise

open Pilot Convolution

/-- Unit kernel and stride, undilated input, and no padding on a spatial axis.
Kernel dilation and reversal are unrestricted because the kernel has one coordinate. -/
structure IsPointwiseAxis (axis : Axis) : Prop where
  unitKernel : axis.kernelExtent = 1
  unitStride : axis.stride = 1
  unitBaseDilation : axis.baseDilation = 1
  noLowPadding : axis.paddingLow = 0
  noHighPadding : axis.paddingHigh = 0

/-- Every spatial axis obeys the pointwise window conditions. -/
def IsPointwise {rank : Nat} (plan : Plan rank) : Prop :=
  ∀ axis, IsPointwiseAxis (plan.window axis)

/-- The sole kernel coordinate for a unit spatial kernel of arbitrary rank. -/
def kernelIndex {rank : Nat} (plan : Plan rank)
    (unitKernel : ∀ axis, plan.kernelShape axis = 1) : Index plan.kernelShape :=
  fun axis => ⟨0, by rw [unitKernel axis]; decide⟩

/-- Transport an output coordinate to the equal spatial input shape. -/
def inputIndex {rank : Nat} (plan : Plan rank)
    (sameShape : plan.outputShape = plan.inputShape) (output : Index plan.outputShape) :
    Index plan.inputShape :=
  fun axis => Fin.cast (congrFun sameShape axis) (output axis)

/-- A genuine channel-only reduction, with no spatial-window loop or optional sampling. -/
def channelSum {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (sameShape : plan.outputShape = plan.inputShape)
    (unitKernel : ∀ axis, plan.kernelShape axis = 1)
    (input : Input plan α) (kernel : Kernel plan α) : OutputIndex plan → α :=
  fun output => ∑ channel : Fin plan.inputFeaturesPerGroup,
    input (FiniteProduct.join output.batchGroup output.batch)
        (FiniteProduct.join output.featureGroup channel)
        (inputIndex plan sameShape output.spatial) *
      kernel output.batchGroup output.featureGroup output.feature channel
        (kernelIndex plan unitKernel)

end TensorRewrite.Theory.ConvolutionPointwise
