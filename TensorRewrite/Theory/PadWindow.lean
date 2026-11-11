module

public import TensorRewrite.Theory.ReductionWindow
public import TensorRewrite.Theory.LatticeIndex

/-! Independent nonnegative edge/interior padding and a window fused across that padding. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PadWindow

open Pilot

/-- Nonnegative edge padding and positive occupied-point spacing on an original input axis. -/
structure PaddingAxis where
  inputExtent : Nat
  low : Nat
  high : Nat
  spacing : Nat
  spacing_pos : 0 < spacing
deriving Repr

/-- Extent of the padded tensor, retaining empty input as an empty occupied region. -/
def PaddingAxis.outputExtent (axis : PaddingAxis) : Nat :=
  axis.low + Convolution.dilatedExtent axis.inputExtent axis.spacing + axis.high

/-- Pad samples its own bounded coordinate through a separate occupied lattice test. -/
def PaddingAxis.sample? (axis : PaddingAxis) (output : Fin axis.outputExtent) :
    Option (Fin axis.inputExtent) :=
  LatticeIndex.decode? axis.inputExtent axis.spacing axis.spacing_pos
    ((output.val : Int) - axis.low)

/-- A padding configuration followed by arbitrary existing window attributes on every axis.
The window template's input extent is replaced by the derived padded input extent. -/
structure Plan (rank : Nat) where
  padding : Fin rank → PaddingAxis
  window : Fin rank → Convolution.Axis

/-- Original tensor shape before padding. -/
def Plan.inputShape {rank : Nat} (plan : Plan rank) : Shape rank :=
  fun axis => (plan.padding axis).inputExtent

/-- The actual Pad result shape. -/
def Plan.paddedShape {rank : Nat} (plan : Plan rank) : Shape rank :=
  fun axis => (plan.padding axis).outputExtent

/-- Independent multidimensional Pad: any absent coordinate gives the supplied fill value. -/
def padIndex? {rank : Nat} (plan : Plan rank) (output : Index plan.paddedShape) :
    Option (Index plan.inputShape) :=
  if valid : ∀ axis, ((plan.padding axis).sample? (output axis)).isSome then
    some fun axis => ((plan.padding axis).sample? (output axis)).get (valid axis)
  else none

/-- A pure padding operator defined independently of the window being transformed. -/
def pad {rank : Nat} {α : Type} (plan : Plan rank) (fill : α)
    (input : Tensor plan.inputShape α) : Tensor plan.paddedShape α := fun output =>
  match padIndex? plan output with
  | some index => input index
  | none => fill

/-- The original window consumes precisely the inferred Pad output extent. -/
def outerAxis (padding : PaddingAxis) (window : Convolution.Axis) : Convolution.Axis :=
  { window with inputExtent := padding.outputExtent }

/-- Fused low padding moves the Pad low edge through the window's base dilation. -/
def fusedLow (padding : PaddingAxis) (window : Convolution.Axis) : Int :=
  window.paddingLow + (padding.low : Int) * window.baseDilation

/-- Derive the high edge from actual padded and occupied extents, also when input is empty. -/
def fusedHigh (padding : PaddingAxis) (window : Convolution.Axis) : Int :=
  window.paddingHigh +
    Convolution.dilatedExtent padding.outputExtent window.baseDilation -
    (padding.low : Int) * window.baseDilation -
    Convolution.dilatedExtent padding.inputExtent (padding.spacing * window.baseDilation)

/-- Fusion preserves stride/kernel geometry and multiplies the occupied-point spacings. -/
def fusedAxis (padding : PaddingAxis) (window : Convolution.Axis) : Convolution.Axis :=
  { window with
    inputExtent := padding.inputExtent
    baseDilation := padding.spacing * window.baseDilation
    baseDilation_pos := Nat.mul_pos padding.spacing_pos window.baseDilation_pos
    paddingLow := fusedLow padding window
    paddingHigh := fusedHigh padding window }

/-- Original window on the separately padded tensor. -/
def outerWindow {rank : Nat} (plan : Plan rank) : ReductionWindow.Plan rank :=
  ⟨fun axis => outerAxis (plan.padding axis) (plan.window axis)⟩

/-- Composed window operating directly on the original input. -/
def fusedWindow {rank : Nat} (plan : Plan rank) : ReductionWindow.Plan rank :=
  ⟨fun axis => fusedAxis (plan.padding axis) (plan.window axis)⟩

end TensorRewrite.Theory.PadWindow
