module
public import TensorRewrite.Pilot.FiniteProduct

/-! Generic coordinates through a size equality and a product decomposition.
This is a prerequisite candidate, not a tensor rewrite. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.CoordinateBridge
open TensorRewrite.Pilot.FiniteProduct

/-- A cast to a rectangular extent does not change the numeric coordinate. -/
theorem cast_value {extent rows columns : Nat} (h : extent = rows * columns)
    (position : Fin extent) : (Fin.cast h position).val = position.val := rfl

/-- A cast coordinate splits into a bounded block number and local coordinate. -/
theorem cast_div_mod {extent rows columns : Nat} (h : extent = rows * columns)
    (position : Fin extent) :
    (row (Fin.cast h position)).val = position.val / columns ∧
    (column (Fin.cast h position)).val = position.val % columns := by
  exact ⟨rfl, rfl⟩

/-- Reassemble the quotient and remainder after any extent cast. -/
theorem cast_reassemble {extent rows columns : Nat} (h : extent = rows * columns)
    (position : Fin extent) :
    join (row (Fin.cast h position)) (column (Fin.cast h position)) = Fin.cast h position := by
  apply Fin.ext
  exact Nat.div_add_mod' position.val columns

/-- If either factor is zero, no position exists, with no division assumption. -/
theorem no_position_zero_columns (rows : Nat) : ¬ Nonempty (Fin (rows * 0)) := by
  intro ⟨p⟩
  exact Fin.elim0 (by simpa using p)

theorem no_position_zero_rows (columns : Nat) : ¬ Nonempty (Fin (0 * columns)) := by
  intro ⟨p⟩
  exact Fin.elim0 (by simpa using p)

#print axioms cast_value
#print axioms cast_div_mod
#print axioms cast_reassemble
#print axioms no_position_zero_columns
#print axioms no_position_zero_rows
end Heldout.CoordinateBridge
