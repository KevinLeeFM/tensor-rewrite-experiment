module

public import TensorRewrite.Theory.ReductionWindow
public import TensorRewrite.Pilot.Reduction

/-! Canonical mixed kept/full-span windows generated from the existing reduction axis plan. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.FullSpanWindow

open Pilot

/-- A kept axis uses a unit window without stride, dilation, reversal or padding. -/
def keptAxis (extent : Nat) : Convolution.Axis where
  inputExtent := extent
  kernelExtent := 1
  stride := 1
  baseDilation := 1
  kernelDilation := 1
  paddingLow := 0
  paddingHigh := 0
  reversed := false
  stride_pos := by decide
  baseDilation_pos := by decide
  kernelDilation_pos := by decide

/-- A reduced axis spans the whole input extent with a single output position. -/
def reducedAxis (extent : Nat) : Convolution.Axis :=
  { keptAxis extent with kernelExtent := extent }

/-- Build all window axes directly from the kept/reduced dimensions. -/
def windowPlan : (plan : Reduction.Plan) → ReductionWindow.Plan plan.inputRank
  | .scalar => ⟨Fin.elim0⟩
  | .keep extent tail => ⟨Fin.cases (keptAxis extent) (windowPlan tail).window⟩
  | .reduce extent tail => ⟨Fin.cases (reducedAxis extent) (windowPlan tail).window⟩

/-- Input coordinate transport inserts no permutation, padding or arithmetic transformation. -/
def inputIndex : (plan : Reduction.Plan) → Index plan.inputShape →
    Index (windowPlan plan).inputShape
  | .scalar, _ => fun axis => Fin.elim0 axis
  | .keep _ tail, index =>
    Fin.cases (index ⟨0, Nat.zero_lt_succ _⟩) (inputIndex tail (fun axis => index axis.succ))
  | .reduce _ tail, index =>
    Fin.cases (index ⟨0, Nat.zero_lt_succ _⟩) (inputIndex tail (fun axis => index axis.succ))

/-- Recover the original input coordinates from the window plan's input shape. -/
def originalIndex : (plan : Reduction.Plan) → Index (windowPlan plan).inputShape →
    Index plan.inputShape
  | .scalar, _ => fun axis => Fin.elim0 axis
  | .keep _ tail, index =>
    Fin.cases (index ⟨0, Nat.zero_lt_succ _⟩) (originalIndex tail (fun axis => index axis.succ))
  | .reduce _ tail, index =>
    Fin.cases (index ⟨0, Nat.zero_lt_succ _⟩) (originalIndex tail (fun axis => index axis.succ))

end TensorRewrite.Theory.FullSpanWindow
