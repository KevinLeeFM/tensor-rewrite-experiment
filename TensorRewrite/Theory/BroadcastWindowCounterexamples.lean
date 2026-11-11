module

public import TensorRewrite.Theory.BroadcastWindowProof
public import TensorRewrite.Theory.WindowTupleFamilyProof

/-! Necessary coverage/identity/state-transport conditions, without compiler-source conclusions. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BroadcastWindow

open Pilot

/-- A covered singleton expansion with two outputs and a reversed kernel. -/
def coveredPair : Expansion := ⟨2, ⟨1, by decide⟩, ⟨3, by decide⟩, 1, 1, true⟩

/-- A valid geometric expansion used to expose a missing reducer identity. -/
def pairPlan : Plan := .expand coveredPair (by decide) .scalar

/-- Geometry alone cannot remove a nonneutral initializer and its padding contributions. -/
theorem nonneutral_reducer_refuted :
    ReductionWindow.reduce (windowPlan pairPlan) (· + ·) 1 1 (Tensor.constant (5 : Nat))
      (fun _ => ⟨0, by decide +revert⟩) = 7 ∧
    sequence pairPlan (Tensor.constant (5 : Nat)) (fun _ => ⟨0, by decide +revert⟩) = 5 := by
  decide

/-- A padded unit window whose first output misses the sole input entirely. -/
def uncovered : Expansion := ⟨1, ⟨1, by decide⟩, ⟨1, by decide⟩, 1, 1, false⟩

/-- Missing coverage is a real value failure even with neutral addition. -/
theorem uncovered_output_refuted :
    ¬ uncovered.Covers ∧
    ReductionWindow.reduce (show ReductionWindow.Plan 1 from ⟨fun _ => uncovered.axis⟩)
      (· + ·) 0 0 (Tensor.constant (5 : Nat)) (fun _ => ⟨0, by decide +revert⟩) = 0 := by
  decide

/-- A coupled two-component reducer uses the other component in each result coordinate. -/
def coupledReducer (first second : Fin 2 → Nat) : Fin 2 → Nat :=
  fun component => if component.val = 0 then first 0 + second 1 else first 1 + second 0

/-- General state projection is not singleton-tuple unpacking and need not preserve the reducer. -/
theorem coupled_projection_refuted :
    (ReductionWindow.reduce (show ReductionWindow.Plan 0 from ⟨Fin.elim0⟩)
      coupledReducer (fun _ => 0) (fun _ => 0)
      (fun _ component => if component.val = 0 then 0 else 1)
      (fun axis => Fin.elim0 axis)) 0 = 1 ∧
    ReductionWindow.reduce (show ReductionWindow.Plan 0 from ⟨Fin.elim0⟩)
      (· + ·) 0 0 (Tensor.constant (0 : Nat)) (fun axis => Fin.elim0 axis) = 0 := by
  decide

end TensorRewrite.Theory.BroadcastWindow
