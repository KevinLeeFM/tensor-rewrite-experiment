module

public import TensorRewrite.Theory.PrefixWindowInteger

/-! Necessary initializer and count-conversion conditions, without compiler/source claims. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PrefixWindow

open Pilot

/-- A one-dimensional prefix plan for closed semantic controls. -/
def shortScan (extent : Nat) : Plan 1 := .scan extent Fin.elim0 Fin.elim0

/-- Dropping leading padding without the initializer fixed point changes the actual fold. -/
theorem nonfixed_padding_refuted :
    ReductionWindow.reduce (windowPlan (shortScan 3)) (· + ·) 1 1
      (Tensor.constant (1 : Nat)) (fun _ => ⟨0, by decide +revert⟩) = 4 ∧
    (prefixValues (shortScan 3) (Tensor.constant (1 : Nat))
      (fun _ => ⟨0, by decide +revert⟩)).foldl (· + ·) 1 = 2 := by
  decide

/-- Actual word prefix counts can wrap unsigned or become negative when interpreted as signed. -/
theorem word_count_overflow_refuted :
    (ReductionWindow.reduce (windowPlan (shortScan 4)) (· + ·) 0 0
      (Tensor.constant (1#2)) (fun _ => ⟨3, by decide +revert⟩)).toNat = 0 ∧
    (ReductionWindow.reduce (windowPlan (shortScan 2)) (· + ·) 0 0
      (Tensor.constant (1#2)) (fun _ => ⟨1, by decide +revert⟩)).toInt = -2 := by
  decide

/-- The exact 32/64-bit signed thresholds are conversion failures for nonnegative counts. -/
theorem signed_width_boundary_refuted :
    (BitVec.ofNat 32 (2 ^ 31)).toInt = -(2 ^ 31 : Int) ∧
    (BitVec.ofNat 64 (2 ^ 63)).toInt = -(2 ^ 63 : Int) := by
  decide

end TensorRewrite.Theory.PrefixWindow
