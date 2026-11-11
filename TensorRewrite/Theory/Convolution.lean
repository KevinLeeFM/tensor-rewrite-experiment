module

public import Mathlib.Data.Fintype.Pi
public import Mathlib.Algebra.BigOperators.Ring.List
public import TensorRewrite.Pilot.FiniteProduct
public import TensorRewrite.Pilot.LinearIndex

/-! Factored, exact static convolution. Batch/feature groups are explicit axes.
Window geometry derives bounded input coordinates; out-of-range or base-dilation
holes contribute zero. This is semiring value semantics, not an IEEE accumulation contract. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Convolution

open Pilot

/-- One spatial convolution axis, including signed padding and both dilations. -/
structure Axis where
  inputExtent : Nat
  kernelExtent : Nat
  stride : Nat
  baseDilation : Nat
  kernelDilation : Nat
  paddingLow : Int
  paddingHigh : Int
  reversed : Bool
  stride_pos : 0 < stride
  baseDilation_pos : 0 < baseDilation
  kernelDilation_pos : 0 < kernelDilation
deriving Repr

/-- Extent of a dilated finite axis, with empty input remaining empty. -/
def dilatedExtent (extent dilation : Nat) : Nat :=
  if extent = 0 then 0 else (extent - 1) * dilation + 1

/-- Number of complete output window positions after signed padding. -/
def Axis.outputExtent (axis : Axis) : Nat :=
  ((axis.paddingLow + dilatedExtent axis.inputExtent axis.baseDilation + axis.paddingHigh -
    dilatedExtent axis.kernelExtent axis.kernelDilation) / (axis.stride : Int) + 1).toNat

/-- Candidate coordinate in the dilated base, accounting for kernel reversal. -/
def Axis.basePosition (axis : Axis) (output : Nat) (kernel : Fin axis.kernelExtent) : Int :=
  (output : Int) * axis.stride +
    ((if axis.reversed then kernel.rev.val else kernel.val) : Int) * axis.kernelDilation -
    axis.paddingLow

/-- Return a bounded input coordinate only on an occupied base-dilation position. -/
def Axis.inputIndex? (axis : Axis) (output : Nat) (kernel : Fin axis.kernelExtent) :
    Option (Fin axis.inputExtent) :=
  let position := axis.basePosition output kernel
  if valid : 0 ≤ position ∧ position % (axis.baseDilation : Int) = 0 ∧
      position / (axis.baseDilation : Int) < axis.inputExtent then
    some ⟨(position / (axis.baseDilation : Int)).toNat, by
      have nonnegative : 0 ≤ position / (axis.baseDilation : Int) :=
        Int.ediv_nonneg valid.1 (by omega)
      omega⟩
  else none

/-- Factored grouping and arbitrary spatial geometry; zero extents are representable. -/
structure Plan (spatialRank : Nat) where
  batchGroups : Nat
  featureGroups : Nat
  batchesPerGroup : Nat
  inputFeaturesPerGroup : Nat
  outputFeaturesPerGroup : Nat
  window : Fin spatialRank → Axis

/-- Original spatial input shape. -/
def Plan.inputShape {rank : Nat} (plan : Plan rank) : Shape rank :=
  fun axis => (plan.window axis).inputExtent

/-- Spatial kernel shape. -/
def Plan.kernelShape {rank : Nat} (plan : Plan rank) : Shape rank :=
  fun axis => (plan.window axis).kernelExtent

/-- Spatial output shape derived from the window geometry. -/
def Plan.outputShape {rank : Nat} (plan : Plan rank) : Shape rank :=
  fun axis => (plan.window axis).outputExtent

/-- Input tensors use flattened group/batch and group/input-channel coordinates. -/
abbrev Input {rank : Nat} (plan : Plan rank) (α : Type) :=
  Fin (plan.batchGroups * plan.batchesPerGroup) →
    Fin (plan.featureGroups * plan.inputFeaturesPerGroup) → Index plan.inputShape → α

/-- Kernel tensors retain batch group, feature group and output channel explicitly. -/
abbrev Kernel {rank : Nat} (plan : Plan rank) (α : Type) :=
  Fin plan.batchGroups → Fin plan.featureGroups → Fin plan.outputFeaturesPerGroup →
    Fin plan.inputFeaturesPerGroup → Index plan.kernelShape → α

/-- A bounded output coordinate in the factored convolution. -/
structure OutputIndex {rank : Nat} (plan : Plan rank) where
  batch : Fin plan.batchesPerGroup
  batchGroup : Fin plan.batchGroups
  featureGroup : Fin plan.featureGroups
  feature : Fin plan.outputFeaturesPerGroup
  spatial : Index plan.outputShape

/-- Combine all axis samples, returning none if any axis is padding or a dilation hole. -/
def spatialInput? {rank : Nat} (plan : Plan rank) (output : Index plan.outputShape)
    (kernel : Index plan.kernelShape) : Option (Index plan.inputShape) :=
  if valid : ∀ axis, ((plan.window axis).inputIndex? (output axis).val (kernel axis)).isSome then
    some fun axis =>
      ((plan.window axis).inputIndex? (output axis).val (kernel axis)).get (valid axis)
  else none

/-- One channel/kernel-position contribution; invalid spatial samples contribute zero. -/
def term {rank : Nat} {α : Type} [Mul α] [Zero α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α) (output : OutputIndex plan)
    (position : Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape)) : α :=
  let channel := FiniteProduct.row position
  let spatial := LinearIndex.delinearize plan.kernelShape (FiniteProduct.column position)
  match spatialInput? plan output.spatial spatial with
  | none => 0
  | some coordinates =>
    input (FiniteProduct.join output.batchGroup output.batch)
        (FiniteProduct.join output.featureGroup channel) coordinates *
      kernel output.batchGroup output.featureGroup output.feature channel spatial

/-- Exact semiring convolution with channels outermost and kernel positions innermost. -/
def convolve {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α) : OutputIndex plan → α :=
  fun output => ((List.finRange
    (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape)).map
      (term plan input kernel output)).sum

end TensorRewrite.Theory.Convolution
