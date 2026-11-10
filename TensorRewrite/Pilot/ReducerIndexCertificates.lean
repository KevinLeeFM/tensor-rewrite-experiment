module

public import TensorRewrite.Pilot.ReducerIndexLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.ReducerIndex

namespace ScatterRoles

/-- The separate Add operand in the native witness. -/
def lhs : Fin 2 → BitVec 32 := fun _ => 1

/-- The original Scatter base in the native witness. -/
def base : Fin 2 → BitVec 32 := fun _ => 3

/-- Repeating parameter0 changes7 to8 at the updated element. -/
theorem repeated_current_changes :
    (before .current .current lhs base 0 5 0).toInt = 7 ∧
      (after .current .current lhs base 0 5 0).toInt = 8 := by decide

/-- Repeating parameter1 instead changes11 to10. -/
theorem repeated_update_changes :
    (before .update .update lhs base 0 5 0).toInt = 11 ∧
      (after .update .update lhs base 0 5 0).toInt = 10 := by decide

/-- The opcode-only Parameter matcher cannot justify universal word preservation. -/
theorem not_universally_preserving :
    ¬ (∀ first second, before first second lhs base 0 5 = after first second lhs base 0 5) := by
  intro preserving
  have value := congrFun (preserving .current .current) 0
  exact (by decide : before .current .current lhs base 0 5 0 ≠
    after .current .current lhs base 0 5 0) value

end ScatterRoles

namespace GatherLiterals

/-- The problematic generated literal has a negative signed8 interpretation. -/
theorem literal_128_narrows : (BitVec.ofNat 8 128).toInt = -128 := by decide

/-- Index zero selects element128 after narrowing the final generated literal. -/
theorem zero_index_changes : originalIndex 129 0#8 = 0 ∧ selectedIndex 129 0#8 = 128 := by decide

/-- A negative signed8 start demonstrates the same wrong final selection. -/
theorem negative_index_changes :
    originalIndex 129 (-1 : BitVec 8) = 0 ∧ selectedIndex 129 (-1 : BitVec 8) = 128 := by decide

/-- Even the largest positive signed8 index is overwritten by the narrowed final literal. -/
theorem maximum_index_changes :
    originalIndex 129 127#8 = 127 ∧ selectedIndex 129 127#8 = 128 := by decide

/-- The unrolling guard alone cannot justify all signed8 index values. -/
theorem not_universally_preserving :
    ¬ (∀ index : BitVec 8, originalIndex 129 index = selectedIndex 129 index) := by
  intro preserving
  exact (by decide : originalIndex 129 0#8 ≠ selectedIndex 129 0#8) (preserving 0#8)

end GatherLiterals
end TensorRewrite.Pilot.ReducerIndex
