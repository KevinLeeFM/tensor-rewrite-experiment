module

public import TensorRewrite.Theory.ConvolutionPointwiseLemmas
public import TensorRewrite.Theory.FiniteSum

/-! Mixed unit-kernel/spanning-window convolution as products with a smaller reduction domain. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConvolutionSeparable

open Pilot Convolution

/-- An undilated, unpadded unit-stride axis with either a unit kernel or one output position. -/
structure IsSeparableAxis (axis : Axis) : Prop where
  unitStride : axis.stride = 1
  unitBaseDilation : axis.baseDilation = 1
  unitKernelDilation : axis.kernelDilation = 1
  noLowPadding : axis.paddingLow = 0
  noHighPadding : axis.paddingHigh = 0
  degenerate : axis.kernelExtent = 1 ∨ axis.outputExtent = 1

/-- The mixed-window conditions hold independently on every spatial axis. -/
def IsSeparable {rank : Nat} (plan : Plan rank) : Prop :=
  ∀ axis, IsSeparableAxis (plan.window axis)

/-- Shape relations used to construct bounded product coordinates; derived from the window. -/
structure Geometry {rank : Nat} (plan : Plan rank) : Prop where
  unit : ∀ axis, plan.kernelShape axis = 1 → plan.outputShape axis = plan.inputShape axis
  spanning : ∀ axis, plan.kernelShape axis ≠ 1 →
    plan.outputShape axis = 1 ∧ plan.kernelShape axis = plan.inputShape axis

/-- Only nonunit spatial kernel axes need reduction; zero extents remain included. -/
abbrev ReducedAxis {rank : Nat} (plan : Plan rank) :=
  {axis : Fin rank // plan.kernelShape axis ≠ 1}

/-- A reduction coordinate has no component for a unit-kernel axis. -/
abbrev ReducedIndex {rank : Nat} (plan : Plan rank) :=
  (axis : ReducedAxis plan) → Fin (plan.kernelShape axis.val)

/-- Insert the unique zero coordinates on removed unit-kernel axes. -/
def expandKernel {rank : Nat} (plan : Plan rank) (index : ReducedIndex plan) :
    Index plan.kernelShape :=
  fun axis => if unit : plan.kernelShape axis = 1 then ⟨0, by omega⟩
    else index ⟨axis, unit⟩

/-- Project a full kernel coordinate onto precisely the retained reduction axes. -/
def projectKernel {rank : Nat} (plan : Plan rank) (index : Index plan.kernelShape) :
    ReducedIndex plan :=
  fun axis => index axis.val

/-- Reverse selected kernel axes, independently of the reduction-axis projection. -/
def reverseKernel {rank : Nat} (plan : Plan rank) (index : Index plan.kernelShape) :
    Index plan.kernelShape :=
  fun axis => if (plan.window axis).reversed then (index axis).rev else index axis

/-- Read output coordinates on unit-kernel axes and reduction coordinates on spanning axes. -/
def productInputIndex {rank : Nat} (plan : Plan rank) (geometry : Geometry plan)
    (output : Index plan.outputShape) (kernel : Index plan.kernelShape) : Index plan.inputShape :=
  fun axis => if unit : (plan.window axis).kernelExtent = 1 then
    Fin.cast (geometry.unit axis unit) (output axis)
  else Fin.cast (geometry.spanning axis unit).2 (kernel axis)

/-- The sole channel in a one-input-channel group. -/
def channelZero {rank : Nat} (plan : Plan rank) (single : plan.inputFeaturesPerGroup = 1) :
    Fin plan.inputFeaturesPerGroup := ⟨0, by omega⟩

/-- Broadcast/product followed by reduction over nonunit kernel axes only.
Reversal is applied to the kernel operand; input coordinates are un-reversed. -/
def productReduction {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (geometry : Geometry plan) (single : plan.inputFeaturesPerGroup = 1)
    (input : Input plan α) (kernel : Kernel plan α) : OutputIndex plan → α :=
  fun output => ∑ reduced : ReducedIndex plan,
    input (FiniteProduct.join output.batchGroup output.batch)
        (FiniteProduct.join output.featureGroup (channelZero plan single))
        (productInputIndex plan geometry output.spatial (expandKernel plan reduced)) *
      kernel output.batchGroup output.featureGroup output.feature (channelZero plan single)
        (reverseKernel plan (expandKernel plan reduced))

end TensorRewrite.Theory.ConvolutionSeparable
