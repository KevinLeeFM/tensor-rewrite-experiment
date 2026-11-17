module
public import TensorRewrite.Pilot.FiniteProductLemmas

/-! Generic component recovery for an equal packed rectangular coordinate. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.WorkerIndexJoin
open TensorRewrite.Pilot.FiniteProduct

/-- Equal packed rectangular coordinates have equal row and column components. -/
theorem join_components_equal {rows columns : Nat}
    (leftRow rightRow : Fin rows) (leftColumn rightColumn : Fin columns)
    (packed : (join leftRow leftColumn).val = (join rightRow rightColumn).val) :
    leftRow = rightRow ∧ leftColumn = rightColumn := by
  have same : join leftRow leftColumn = join rightRow rightColumn := Fin.ext packed
  constructor
  · rw [← row_join leftRow leftColumn, same, row_join]
  · rw [← column_join leftRow leftColumn, same, column_join]


/-- Equality of the natural packed values, with matching row/column extents,
recovers the natural values of both components. -/
theorem packed_component_values {rows₁ rows₂ cols₁ cols₂ : Nat}
    (sameRows : rows₁ = rows₂) (sameCols : cols₁ = cols₂)
    (leftRow : Fin rows₁) (rightRow : Fin rows₂)
    (leftColumn : Fin cols₁) (rightColumn : Fin cols₂)
    (packed : (join leftRow leftColumn).val = (join rightRow rightColumn).val) :
    leftRow.val = rightRow.val ∧ leftColumn.val = rightColumn.val := by
  subst rows₂
  subst cols₂
  exact join_components_equal leftRow rightRow leftColumn rightColumn packed |>.imp
    (by intro h; exact congrArg Fin.val h) (by intro h; exact congrArg Fin.val h)

#print axioms join_components_equal
#print axioms packed_component_values
end Heldout.WorkerIndexJoin
