module

public import TensorRewrite.Theory.ConcatenationSlice
public import TensorRewrite.Theory.SlicePadLemmas
public import TensorRewrite.Theory.ShapeTransportLemmas
public import TensorRewrite.Theory.ControlValues

/-! Actual static Slice and Pad attributes for further arbitrary-axis concatenation graphs. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Concatenation

open Pilot

/-- A common legal Slice on every non-concatenated axis; selected-axis intervals vary separately. -/
structure Crop {rank : Nat} (inputFrame : Frame rank) where
  outputExtents : Shape rank
  attributes : Fin rank → SliceShape.Axis
  validOther : ∀ axis, axis ≠ inputFrame.axis →
    SliceShape.IsWellFormed (inputFrame.extents axis) (outputExtents axis) (attributes axis)

/-- The Slice output frame retains the actual selected axis and the common other output extents. -/
def Crop.outputFrame {rank : Nat} {inputFrame : Frame rank} (crop : Crop inputFrame) : Frame rank :=
  ⟨crop.outputExtents, inputFrame.axis⟩

/-- Replace only the selected Slice attributes, preserving all other actual axes. -/
def Crop.axesWith {rank : Nat} {inputFrame : Frame rank} (crop : Crop inputFrame)
    (selected : SliceShape.Axis) : Fin rank → SliceShape.Axis := fun axis =>
  if axis = inputFrame.axis then selected else crop.attributes axis

/-- Ordinary Slice with independently legal selected attributes and common other axes. -/
def Crop.sliceWith {rank extent : Nat} {inputFrame : Frame rank} (crop : Crop inputFrame)
    (selected : SliceShape.Axis) (length : Nat)
    (validSelected : SliceShape.IsWellFormed extent length selected) : SlicePad.Slice rank where
  inputShape := inputFrame.shape extent
  outputShape := crop.outputFrame.shape length
  axes := crop.axesWith selected
  valid axis := by
    by_cases same : axis = inputFrame.axis
    · simpa [Frame.shape, Crop.outputFrame, Crop.axesWith, same] using validSelected
    · simpa [Frame.shape, Crop.outputFrame, Crop.axesWith, same] using crop.validOther axis same

/-- An actual scalar Broadcast operand represented at its declared selected extent. -/
def constantBlock {rank : Nat} {frame : Frame rank} {α : Type}
    (extent : Nat) (value : α) : Block frame α :=
  ⟨extent, ControlValues.broadcast (ControlValues.scalarAxes rank)
    (fun axis => Fin.elim0 axis) (Tensor.constant (shape := (Fin.elim0 : Shape 0)) value)⟩

/-- A Slice operand carries its original checked attributes and independently declared extent. -/
def Crop.blockWith {rank extent : Nat} {inputFrame : Frame rank} {α : Type}
    (crop : Crop inputFrame) (input : Tensor (inputFrame.shape extent) α)
    (selected : SliceShape.Axis) (length : Nat)
    (validSelected : SliceShape.IsWellFormed extent length selected) : Block crop.outputFrame α :=
  ⟨length, (crop.sliceWith selected length validSelected).tensor input⟩

/-- The actual proposed merged Slice keeps the first start/stride and the final exclusive limit. -/
def mergeAxis (first second : SliceShape.Axis) : SliceShape.Axis :=
  { first with limit := second.limit }

/-- Put all nonnegative boundary padding on the selected axis, leaving every other axis alone. -/
def Frame.edgePadding {rank : Nat} (frame : Frame rank) (low high : Nat) :
    SlicePad.Padding rank where
  low axis := if axis = frame.axis then low else 0
  high axis := if axis = frame.axis then high else 0

end TensorRewrite.Theory.Concatenation
