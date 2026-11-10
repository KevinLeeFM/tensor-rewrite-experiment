module

public import TensorRewrite.Pilot.NestedUnsigned64

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.NestedUnsigned64

/-- A high-bit inner start changes the evaluator-relative selected coordinate. -/
theorem inner_high_changes :
    originalStart (BitVec.ofNat 64 (2 ^ 63)) 1 = 1 ∧
      rewrittenStart (BitVec.ofNat 64 (2 ^ 63)) 1 = 5 := by decide

/-- A high-bit outer start has the same evaluator-relative difference. -/
theorem outer_high_changes :
    originalStart 1 (BitVec.ofNat 64 (2 ^ 63)) = 1 ∧
      rewrittenStart 1 (BitVec.ofNat 64 (2 ^ 63)) = 5 := by decide

/-- Two high-bit starts select opposite edges in the two evaluator profiles. -/
theorem both_high_changes :
    originalStart (BitVec.ofNat 64 (2 ^ 63)) (BitVec.ofNat 64 (2 ^ 63)) = 0 ∧
      rewrittenStart (BitVec.ofNat 64 (2 ^ 63)) (BitVec.ofNat 64 (2 ^ 63)) = 8 := by decide

/-- Universal preservation fails in the explicitly observed evaluator profile. -/
theorem not_universally_preserving :
    ¬ (∀ inner outer : BitVec 64, originalStart inner outer = rewrittenStart inner outer) := by
  intro preserving
  have equality := preserving (BitVec.ofNat 64 (2 ^ 63)) 1
  rw [inner_high_changes.1, inner_high_changes.2] at equality
  exact (by decide : (1 : Int) ≠ 5) equality

end TensorRewrite.Pilot.NestedUnsigned64
