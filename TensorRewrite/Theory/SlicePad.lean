module

public import TensorRewrite.Theory.ReductionWindow
public import TensorRewrite.Pilot.IndexMaps

/-! Independent typed Slice and nonnegative Pad operators, with derived affine factor data. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.SlicePad

open Pilot

/-- A bounded affine output-to-input axis; output extent is an explicit shape parameter. -/
structure Axis where
  inputExtent : Nat
  outputExtent : Nat
  stride : Nat
  low : Int
  stride_pos : 0 < stride

/-- Ceiling division by a positive natural step, including negative positions. -/
def ceilDiv (position : Int) (stride : Nat) : Int := -((-position) / (stride : Int))

/-- First potentially valid output, clipped to the actual output extent. -/
def Axis.first (axis : Axis) : Nat :=
  min axis.outputExtent (ceilDiv axis.low axis.stride).toNat

/-- End of the valid output interval, also clipped to the actual output extent. -/
def Axis.last (axis : Axis) : Nat :=
  min axis.outputExtent (ceilDiv (axis.low + axis.inputExtent) axis.stride).toNat

/-- Number of valid output samples to retain in the Slice. -/
def Axis.count (axis : Axis) : Nat := axis.last - axis.first

/-- A legal empty-Slice start even when every output lies outside the input. -/
def Axis.start (axis : Axis) : Nat :=
  min axis.inputExtent (((axis.first : Int) * axis.stride - axis.low).toNat)

/-- Exclusive Slice limit, retaining exact count and avoiding negative empty extents. -/
def Axis.limit (axis : Axis) : Nat :=
  if axis.count = 0 then axis.start else axis.start + (axis.count - 1) * axis.stride + 1

/-- Actual Slice attributes, rather than an assumed coordinate equivalence. -/
def Axis.attributes (axis : Axis) : SliceShape.Axis where
  start := axis.start
  limit := axis.limit
  stride := axis.stride

/-- Read the affine data from a window plan; no unit/undilated assumption is needed to form it. -/
def windowAxis {rank : Nat} (plan : ReductionWindow.Plan rank) (index : Fin rank) : Axis where
  inputExtent := (plan.window index).inputExtent
  outputExtent := (plan.window index).outputExtent
  stride := (plan.window index).stride
  low := (plan.window index).paddingLow
  stride_pos := (plan.window index).stride_pos

/-- Typed static Slice with ordinary start/limit/stride well-formedness. -/
structure Slice (rank : Nat) where
  inputShape : Shape rank
  outputShape : Shape rank
  axes : Fin rank → SliceShape.Axis
  valid : ∀ axis, SliceShape.IsWellFormed (inputShape axis) (outputShape axis) (axes axis)

/-- Slice reads the existing bounded start+stride*coordinate index map. -/
def Slice.tensor {rank : Nat} {α : Type} (slice : Slice rank)
    (input : Tensor slice.inputShape α) : Tensor slice.outputShape α :=
  fun output => input (IndexMaps.sliceIndex slice.axes slice.valid output)

/-- Nonnegative padding on both sides of each tensor axis. -/
structure Padding (rank : Nat) where
  low : Fin rank → Nat
  high : Fin rank → Nat

/-- Pad's output shape is independently computed from its input shape and padding. -/
def Padding.outputShape {rank : Nat} (padding : Padding rank) (inputShape : Shape rank) :
    Shape rank := fun axis => padding.low axis + inputShape axis + padding.high axis

/-- Pad samples a shifted bounded input coordinate or returns none on its new boundary. -/
def Padding.input? {rank : Nat} (padding : Padding rank) (inputShape : Shape rank)
    (output : Index (padding.outputShape inputShape)) : Option (Index inputShape) :=
  if valid : ∀ axis,
      (ReductionWindow.boundedIndex? (inputShape axis)
        ((output axis).val - (padding.low axis : Int))).isSome then
    some fun axis =>
      (ReductionWindow.boundedIndex? (inputShape axis)
        ((output axis).val - (padding.low axis : Int))).get (valid axis)
  else none

/-- Pad preserves the interior tensor and inserts the supplied value at every boundary position. -/
def Padding.tensor {rank : Nat} {α : Type} (padding : Padding rank) (fill : α)
    {inputShape : Shape rank} (input : Tensor inputShape α) :
    Tensor (padding.outputShape inputShape) α := fun output =>
  match padding.input? inputShape output with
  | some index => input index
  | none => fill

end TensorRewrite.Theory.SlicePad
