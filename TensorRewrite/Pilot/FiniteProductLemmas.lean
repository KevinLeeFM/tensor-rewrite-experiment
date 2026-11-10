module

public import TensorRewrite.Pilot.FiniteProduct

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.FiniteProduct

/-- Row recovery is a left inverse of packing. -/
theorem row_join {rows columns : Nat} (r : Fin rows) (c : Fin columns) :
    row (join r c) = r := by
  apply Fin.ext
  change (r.val * columns + c.val) / columns = r.val
  rw [Nat.mul_comm r.val columns, Nat.mul_add_div (Nat.zero_lt_of_lt c.isLt),
    Nat.div_eq_of_lt c.isLt, Nat.add_zero]

/-- Column recovery is a left inverse of packing. -/
theorem column_join {rows columns : Nat} (r : Fin rows) (c : Fin columns) :
    column (join r c) = c := by
  apply Fin.ext
  change (r.val * columns + c.val) % columns = c.val
  rw [Nat.mul_comm r.val columns, Nat.mul_add_mod, Nat.mod_eq_of_lt c.isLt]

/-- Packing recovered coordinates is the identity on every admitted position. -/
theorem join_row_column {rows columns : Nat} (position : Fin (rows * columns)) :
    join (row position) (column position) = position := by
  apply Fin.ext
  exact Nat.div_add_mod' position.val columns

end TensorRewrite.Pilot.FiniteProduct
