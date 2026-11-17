module
public import GoalCandidate
@[expose] public section
set_option autoImplicit false
namespace Heldout.SpaceDepthCandidate
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex

/-- The row selected from a packed row/column coordinate is the original row. -/
private theorem row_join {rows cols : Nat} (r : Fin rows) (c : Fin cols) :
    FiniteProduct.row (FiniteProduct.join r c) = r := by
  apply Fin.ext
  simp only [FiniteProduct.row, FiniteProduct.join]
  have positive : 0 < cols := Nat.zero_lt_of_lt c.isLt
  rw [Nat.mul_comm r.val cols, Nat.mul_add_div positive, Nat.div_eq_of_lt c.isLt]
  simp

/-- The column selected from a packed row/column coordinate is the original column. -/
private theorem column_join {rows cols : Nat} (r : Fin rows) (c : Fin cols) :
    FiniteProduct.column (FiniteProduct.join r c) = c := by
  apply Fin.ext
  simp only [FiniteProduct.column, FiniteProduct.join]
  rw [Nat.mul_comm r.val cols, Nat.mul_add_mod]
  exact Nat.mod_eq_of_lt c.isLt

/-- Every admitted logical coordinate is recovered from its row-major linear position. -/
private theorem delinearize_linearize : ∀ {rank : Nat} (shape : Shape rank)
    (index : Index shape), delinearize shape (linearize shape index) = index := by
  intro rank
  induction rank with
  | zero =>
      intro shape index
      funext axis
      exact Fin.elim0 axis
  | succ rank ih =>
      intro shape index
      funext axis
      cases axis using Fin.cases with
      | zero =>
          change FiniteProduct.row (FiniteProduct.join (index 0)
            (linearize (fun i => shape i.succ) (fun i => index i.succ))) = index 0
          exact row_join (index 0) _
      | succ axis =>
          simp only [linearize, delinearize, Fin.cases_succ]
          rw [column_join]
          exact congrFun (ih (fun i => shape i.succ) (fun i => index i.succ)) axis

#print axioms delinearize_linearize
end Heldout.SpaceDepthCandidate
