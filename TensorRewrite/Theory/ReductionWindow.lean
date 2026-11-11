module

public import TensorRewrite.Theory.ConvolutionPointwise

/-! Ordered reduction windows with explicit initializer and invalid-sample value.
Axis geometry is shared with convolution; no scalar algebra or execution backend is assumed. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ReductionWindow

open Pilot

/-- A window on every logical tensor axis, with positive stride and dilation. -/
structure Plan (rank : Nat) where
  window : Fin rank → Convolution.Axis

/-- Reuse only the existing bounded convolution sampler, with trivial unused groups. -/
def Plan.asConvolution {rank : Nat} (plan : Plan rank) : Convolution.Plan rank where
  batchGroups := 1
  featureGroups := 1
  batchesPerGroup := 1
  inputFeaturesPerGroup := 1
  outputFeaturesPerGroup := 1
  window := plan.window

/-- Input extents on every axis. -/
def Plan.inputShape {rank : Nat} (plan : Plan rank) : Shape rank :=
  plan.asConvolution.inputShape

/-- Window extents, enumerated in logical row-major order. -/
def Plan.kernelShape {rank : Nat} (plan : Plan rank) : Shape rank :=
  plan.asConvolution.kernelShape

/-- Output extents derived from the signed window geometry. -/
def Plan.outputShape {rank : Nat} (plan : Plan rank) : Shape rank :=
  plan.asConvolution.outputShape

/-- Sample only occupied bounded input coordinates; padding and dilation holes return none. -/
def sample? {rank : Nat} (plan : Plan rank) (output : Index plan.outputShape)
    (kernel : Index plan.kernelShape) : Option (Index plan.inputShape) :=
  Convolution.spatialInput? plan.asConvolution output kernel

/-- Every invalid sample is a value in the fold, supplied independently of its initializer. -/
def contribution {rank : Nat} {α : Type} (plan : Plan rank) (padding : α)
    (input : Tensor plan.inputShape α) (output : Index plan.outputShape)
    (kernel : Index plan.kernelShape) : α :=
  match sample? plan output kernel with
  | some index => input index
  | none => padding

/-- Complete ordered sample list, including every invalid position's padding value. -/
def values {rank : Nat} {α : Type} (plan : Plan rank) (padding : α)
    (input : Tensor plan.inputShape α) (output : Index plan.outputShape) : List α :=
  (List.finRange (LinearIndex.elementCount plan.kernelShape)).map fun position =>
    contribution plan padding input output (LinearIndex.delinearize plan.kernelShape position)

/-- Fold every sampled window from the actual initializer; padding is not skipped. -/
def reduce {rank : Nat} {α : Type} (plan : Plan rank) (operation : α → α → α)
    (initial padding : α) (input : Tensor plan.inputShape α) : Tensor plan.outputShape α :=
  fun output => (values plan padding input output).foldl operation initial

/-- Every window extent is one; stride, padding and both dilations remain explicit. -/
def IsUnit {rank : Nat} (plan : Plan rank) : Prop :=
  ∀ axis, (plan.window axis).kernelExtent = 1

/-- Input samples have no base-dilation holes. -/
def IsUndilated {rank : Nat} (plan : Plan rank) : Prop :=
  ∀ axis, (plan.window axis).baseDilation = 1

/-- Canonical coordinate of a unit window of arbitrary rank. -/
def unitIndex {rank : Nat} (plan : Plan rank) (unit : IsUnit plan) : Index plan.kernelShape :=
  ConvolutionPointwise.kernelIndex plan.asConvolution unit

/-- A bounded coordinate from a signed position; negative or too-large positions are invalid. -/
def boundedIndex? (extent : Nat) (position : Int) : Option (Fin extent) :=
  if valid : 0 ≤ position ∧ position < (extent : Int) then
    some ⟨position.toNat, (Int.toNat_lt valid.1).mpr valid.2⟩
  else none

/-- Affine crop/stride position, independent of a window coordinate. -/
def affinePosition {rank : Nat} (plan : Plan rank) (output : Index plan.outputShape)
    (axis : Fin rank) : Int :=
  (output axis).val * (plan.window axis).stride - (plan.window axis).paddingLow

/-- A separate crop/stride gather map using signed bounds without dilation or window sampling. -/
def affineInput? {rank : Nat} (plan : Plan rank) (output : Index plan.outputShape) :
    Option (Index plan.inputShape) :=
  if valid : ∀ axis,
      (boundedIndex? ((plan.window axis).inputExtent) (affinePosition plan output axis)).isSome then
    some fun axis =>
      (boundedIndex? ((plan.window axis).inputExtent)
        (affinePosition plan output axis)).get (valid axis)
  else none

/-- Map valid gathered input values and fill invalid output positions with the target pad value. -/
def gatherMap {rank : Nat} {α β : Type} (plan : Plan rank) (padding : β) (f : α → β)
    (input : Tensor plan.inputShape α) : Tensor plan.outputShape β := fun output =>
  match affineInput? plan output with
  | some index => f (input index)
  | none => padding

end TensorRewrite.Theory.ReductionWindow
