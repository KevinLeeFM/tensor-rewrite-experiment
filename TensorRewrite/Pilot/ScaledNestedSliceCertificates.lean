module

public import TensorRewrite.Pilot.ScaledNestedSlice

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.ScaledNestedSlice

/-- Retaining the original multiplication gives the selected word times the multiplier. -/
theorem original_witness (multiplier : BitVec 32) :
    original 1 (by decide) multiplier 1 2 witnessIndex = 4#32 * multiplier := by rfl

/-- The continuation path instead selects the unscaled fourth input label. -/
theorem rewritten_witness : rewritten 1 (by decide) 1 2 witnessIndex = 4#32 := by rfl

/-- Every multiplier that changes this selected word refutes tensor equality. -/
theorem changes_of_not_fixed (multiplier : BitVec 32) (changed : 4#32 * multiplier ≠ 4#32) :
    original 1 (by decide) multiplier 1 2 ≠ rewritten 1 (by decide) 1 2 := by
  intro equality
  have atIndex := congrFun equality witnessIndex
  rw [original_witness, rewritten_witness] at atIndex
  exact changed atIndex

/-- The ordinary finite S32 witness changes28 to4, without overflow or high-bit indices. -/
theorem multiplier_seven_changes :
    original 1 (by decide) 7 1 2 witnessIndex = 28#32 ∧
      rewritten 1 (by decide) 1 2 witnessIndex = 4#32 := by decide

/-- A runtime negative multiplier gives a distinct signed finite witness. -/
theorem negative_multiplier_changes :
    (original 1 (by decide) (-3) 1 2 witnessIndex).toInt = -12 ∧
      (rewritten 1 (by decide) 1 2 witnessIndex).toInt = 4 := by decide

/-- Runtime zero does not prevent this branch from dropping multiplication. -/
theorem zero_multiplier_changes :
    original 1 (by decide) 0 1 2 witnessIndex = 0#32 ∧
      rewritten 1 (by decide) 1 2 witnessIndex = 4#32 := by decide

/-- The source continuation cannot preserve this expression for all runtime multipliers. -/
theorem not_universally_preserving :
    ¬ (∀ multiplier : BitVec 32,
      original 1 (by decide) multiplier 1 2 = rewritten 1 (by decide) 1 2) := by
  intro preserving
  exact changes_of_not_fixed 7 (by decide) (preserving 7)

end TensorRewrite.Pilot.ScaledNestedSlice
