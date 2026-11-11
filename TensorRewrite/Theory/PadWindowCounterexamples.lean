module

public import TensorRewrite.Theory.PadWindowProof

/-! Concrete mathematical contract failures: empty-input geometry and unequal fill values. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PadWindow

open Pilot

/-- An empty input with two explicit padding positions. -/
def emptyPadding : PaddingAxis := ⟨0, 1, 1, 1, by decide⟩

/-- A unit kernel applied to a base dilated by two. -/
def dilatedWindow : Convolution.Axis where
  inputExtent := 0
  kernelExtent := 1
  stride := 1
  baseDilation := 2
  kernelDilation := 1
  paddingLow := 0
  paddingHigh := 0
  reversed := false
  stride_pos := by decide
  baseDilation_pos := by decide
  kernelDilation_pos := by decide

/-- The usual high-edge formula without an empty-input correction changes output extent. -/
theorem empty_high_formula_refuted :
    (outerAxis emptyPadding dilatedWindow).outputExtent = 3 ∧
    (fusedAxis emptyPadding dilatedWindow).outputExtent = 3 ∧
    ({ fusedAxis emptyPadding dilatedWindow with paddingHigh := 2 }).outputExtent = 4 := by
  decide

/-- A padded one-element tensor and a window with a separate low padding position. -/
def unequalFillPlan : Plan 1 where
  padding := fun _ => ⟨1, 1, 0, 1, by decide⟩
  window := fun _ => { dilatedWindow with
    baseDilation := 1
    paddingLow := 1
    baseDilation_pos := by decide }

/-- Folding different explicit/implicit fill values into one fill changes an actual contribution. -/
theorem unequal_fill_refuted :
    ReductionWindow.contribution (outerWindow unequalFillPlan) 2
      (pad unequalFillPlan 5 (fun _ => (3 : Nat)))
      (fun _ => ⟨1, by decide +revert⟩) (fun _ => ⟨0, by decide +revert⟩) = 5 ∧
    ReductionWindow.contribution (fusedWindow unequalFillPlan) 2 (fun _ => (3 : Nat))
      (fun _ => ⟨1, by decide +revert⟩) (fun _ => ⟨0, by decide +revert⟩) = 2 := by
  decide

end TensorRewrite.Theory.PadWindow
