module

public import Std

/-! Total row-major packing for finite rectangular coordinates. A zero extent
has no coordinate; division is only used on an admitted linear position. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.FiniteProduct

/-- Pack a row and column with the column varying fastest. -/
def join {rows columns : Nat} (row : Fin rows) (column : Fin columns) :
    Fin (rows * columns) :=
  ⟨row.val * columns + column.val, by
    calc
      _ < row.val * columns + columns := Nat.add_lt_add_left column.isLt _
      _ = (row.val + 1) * columns := by rw [Nat.add_mul, Nat.one_mul]
      _ ≤ rows * columns := Nat.mul_le_mul_right columns (Nat.succ_le_of_lt row.isLt)⟩

/-- Recover the row of an admitted linear position. -/
def row {rows columns : Nat} (position : Fin (rows * columns)) : Fin rows :=
  ⟨position.val / columns, Nat.div_lt_of_lt_mul
    (by simpa only [Nat.mul_comm] using position.isLt)⟩

/-- Recover the column; existence of the position excludes a zero column extent. -/
def column {rows columns : Nat} (position : Fin (rows * columns)) : Fin columns :=
  ⟨position.val % columns, by
    have positive : 0 < columns := by
      have bound := position.isLt
      cases columns with
      | zero => simp at bound
      | succ _ => omega
    exact Nat.mod_lt _ positive⟩

end TensorRewrite.Pilot.FiniteProduct
