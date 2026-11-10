module

public import TensorRewrite.Pilot.LinearIndex
public import TensorRewrite.Pilot.FiniteProductLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.LinearIndex

/-- Recovering packed coordinates is the identity at every rank, including rank zero. -/
theorem delinearize_linearize {rank : Nat} (shape : Shape rank) (index : Index shape) :
    delinearize shape (linearize shape index) = index := by
  induction rank with
  | zero => funext axis; exact Fin.elim0 axis
  | succ rank ih =>
    funext axis
    refine Fin.cases ?_ (fun axis => ?_) axis
    · exact FiniteProduct.row_join _ _
    · change delinearize (fun axis => shape axis.succ)
        (FiniteProduct.column (FiniteProduct.join (index 0)
          (linearize (fun axis => shape axis.succ) (fun axis => index axis.succ)))) axis = _
      rw [FiniteProduct.column_join, ih]

/-- Packing recovered coordinates is the identity on all valid linear positions. -/
theorem linearize_delinearize {rank : Nat} (shape : Shape rank)
    (position : Fin (elementCount shape)) : linearize shape (delinearize shape position) =
      position := by
  induction rank with
  | zero =>
    apply Fin.ext
    change 0 = position.val
    have bound := position.isLt
    change position.val < 1 at bound
    omega
  | succ rank ih =>
    change FiniteProduct.join (FiniteProduct.row position)
      (linearize (fun axis => shape axis.succ)
        (delinearize (fun axis => shape axis.succ) (FiniteProduct.column position))) = _
    rw [ih]
    exact FiniteProduct.join_row_column position

end TensorRewrite.Pilot.LinearIndex
