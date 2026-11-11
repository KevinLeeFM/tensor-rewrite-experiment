module

public import TensorRewrite.Theory.PadWindowProof
public import TensorRewrite.Theory.BroadcastWindowProof

/-! Raw Pad/window attributes admitted for a derived reshape/Broadcast composition. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PadBroadcast

open Pilot

/-- A kept axis may have edge Pad, canceled by signed outer cropping; occupied spacing is one. -/
structure KeptAxis where
  padding : PadWindow.PaddingAxis
  window : Convolution.Axis
  unitSpacing : padding.spacing = 1
  unitKernel : window.kernelExtent = 1
  unitStride : window.stride = 1
  unitBase : window.baseDilation = 1
  cancelLow : window.paddingLow = -(padding.low : Int)
  cancelHigh : window.paddingHigh = -(padding.high : Int)

/-- Raw attributes for an original singleton input; window dilation is one. -/
structure Expansion where
  padding : PadWindow.PaddingAxis
  window : Convolution.Axis
  singleton : padding.inputExtent = 1
  unitKernelDilation : window.kernelDilation = 1

/-- The occupied original input's offset after Pad low edges pass through base dilation. -/
def Expansion.offset (expansion : Expansion) : Int :=
  expansion.window.paddingLow + (expansion.padding.low : Int) * expansion.window.baseDilation

/-- Coverage is checked against actual outer output bounds and the raw occupied offset. -/
def Expansion.Covers (expansion : Expansion) : Prop :=
  (PadWindow.outerAxis expansion.padding expansion.window).outputExtent = 0 ∨
    (0 ≤ expansion.offset ∧ expansion.offset < expansion.window.kernelExtent ∧
      (((PadWindow.outerAxis expansion.padding expansion.window).outputExtent - 1) *
        expansion.window.stride : Nat) ≤ expansion.offset)

/-- Concrete raw coverage is decidable without a semantic sample-equivalence oracle. -/
instance (expansion : Expansion) : Decidable expansion.Covers := by
  unfold Expansion.Covers
  infer_instance

/-- A derived singleton axis retains actual fused high padding and positive multiplied spacing. -/
def Expansion.broadcast (expansion : Expansion) : BroadcastWindow.Expansion where
  kernelExtent := expansion.window.kernelExtent
  stride := ⟨expansion.window.stride, expansion.window.stride_pos⟩
  baseDilation := ⟨expansion.padding.spacing * expansion.window.baseDilation,
    Nat.mul_pos expansion.padding.spacing_pos expansion.window.baseDilation_pos⟩
  paddingLow := expansion.offset
  paddingHigh := PadWindow.fusedHigh expansion.padding expansion.window
  reversed := expansion.window.reversed

end TensorRewrite.Theory.PadBroadcast
