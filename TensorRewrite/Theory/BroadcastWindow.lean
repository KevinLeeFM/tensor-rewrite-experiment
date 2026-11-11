module

public import TensorRewrite.Theory.FullSpanWindow
public import TensorRewrite.Theory.ConvolutionPointwise
public import TensorRewrite.Pilot.Reduction
public import Mathlib.Data.PNat.Basic

/-! Window geometry whose singleton input axes can expand to many output positions. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BroadcastWindow

open Pilot

/-- Singleton-input window attributes, retaining stride, base spacing, padding and reversal. -/
structure Expansion where
  kernelExtent : Nat
  stride : ℕ+
  baseDilation : ℕ+
  paddingLow : Int
  paddingHigh : Int
  reversed : Bool
deriving Repr

/-- The singleton input has exactly one occupied position, independent of base dilation. -/
def Expansion.axis (expansion : Expansion) : Convolution.Axis where
  inputExtent := 1
  kernelExtent := expansion.kernelExtent
  stride := expansion.stride.val
  baseDilation := expansion.baseDilation.val
  kernelDilation := 1
  paddingLow := expansion.paddingLow
  paddingHigh := expansion.paddingHigh
  reversed := expansion.reversed
  stride_pos := expansion.stride.pos
  baseDilation_pos := expansion.baseDilation.pos
  kernelDilation_pos := by decide

/-- Attribute inequalities force the sole input into the first and last admitted windows.
Empty output is admitted separately, without requiring a kernel coordinate. -/
def Expansion.Covers (expansion : Expansion) : Prop :=
  expansion.axis.outputExtent = 0 ∨
    (0 ≤ expansion.paddingLow ∧ expansion.paddingLow < expansion.kernelExtent ∧
      ((expansion.axis.outputExtent - 1) * expansion.stride.val : Nat) ≤ expansion.paddingLow)

/-- Coverage is decidable from the concrete integer window attributes. -/
instance (expansion : Expansion) : Decidable expansion.Covers := by
  unfold Expansion.Covers
  infer_instance

/-- Kept axes are pointwise; selected singleton axes may have any covered output extent. -/
inductive Plan where
  | scalar
  | keep (axis : Convolution.Axis) (pointwise : ConvolutionPointwise.IsPointwiseAxis axis)
      (tail : Plan)
  | expand (expansion : Expansion) (covers : expansion.Covers) (tail : Plan)

/-- Number of logical input/output axes. -/
def Plan.rank : Plan → Nat
  | .scalar => 0
  | .keep _ _ tail | .expand _ _ tail => tail.rank + 1

/-- The actual window, with output shape derived from its attributes. -/
def windowPlan : (plan : Plan) → ReductionWindow.Plan plan.rank
  | .scalar => ⟨Fin.elim0⟩
  | .keep axis _ tail => ⟨Fin.cases axis (windowPlan tail).window⟩
  | .expand expansion _ tail => ⟨Fin.cases expansion.axis (windowPlan tail).window⟩

/-- Remove exactly the expanded unit input dimensions, retaining the original axis order. -/
def compactPlan : Plan → Reduction.Plan
  | .scalar => .scalar
  | .keep axis _ tail => .keep axis.inputExtent (compactPlan tail)
  | .expand _ _ tail => .reduce 1 (compactPlan tail)

end TensorRewrite.Theory.BroadcastWindow
