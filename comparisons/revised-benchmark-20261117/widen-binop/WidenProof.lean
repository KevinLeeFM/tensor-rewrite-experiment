import WidenSpec
import TensorRewrite.Pilot.PromotedWordArithmetic
set_option autoImplicit false
namespace RevisedBenchmark.Widen
open TensorRewrite.Pilot Tensor PromotedWordArithmetic

private theorem uquot {n w : Nat} (h : n ≤ w) (a b : BitVec n) :
    ((a.setWidth w).udiv (b.setWidth w)).setWidth n = a.udiv b := by
  apply BitVec.eq_of_toNat_eq
  rw [BitVec.toNat_setWidth]
  change ((a.setWidth w).toNat / (b.setWidth w).toNat) % 2 ^ n = a.toNat / b.toNat
  rw [BitVec.toNat_setWidth_of_le h, BitVec.toNat_setWidth_of_le h]
  exact Nat.mod_eq_of_lt (Nat.lt_of_le_of_lt (Nat.div_le_self _ _) a.isLt)

theorem verified (op : Op) : Case op := by
  intro rank n s w h signed legal a b
  funext i
  cases signed with
  | false =>
    cases op <;> simp only [map, map₂, applyOp, convert, Bool.false_eq_true, ite_false]
    · simp only [BitVec.setWidth_add _ _ h, BitVec.setWidth_setWidth_of_le _ h, BitVec.setWidth_eq]
    · simp only [BitVec.sub_eq_add_neg, BitVec.setWidth_add _ _ h, BitVec.setWidth_neg_of_le h,
        BitVec.setWidth_setWidth_of_le _ h, BitVec.setWidth_eq]
    · simp only [BitVec.setWidth_mul _ _ h, BitVec.setWidth_setWidth_of_le _ h, BitVec.setWidth_eq]
    · exact uquot h _ _
  | true =>
    cases op <;> simp only [map, map₂, applyOp, convert, ite_true]
    · rw [signed_cast_narrow h, promoted_add h]
    · rw [signed_cast_narrow h, promoted_sub h]
    · rw [signed_cast_narrow h, promoted_mul h]
    · exact Bool.noConfusion (legal rfl)

example : Case .add := verified .add
example : Case .sub := verified .sub
example : Case .mul := verified .mul
example : Case .udiv := verified .udiv
#print axioms verified
end RevisedBenchmark.Widen
