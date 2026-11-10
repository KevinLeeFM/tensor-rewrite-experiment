import TensorRewrite.Pilot.Indexing

namespace TensorRewrite.Pilot.Subtract

open Tensor

variable {rank : Nat} {shape : Shape rank} {width : Nat}
variable (x y : Tensor shape (BitVec width))

theorem sub_self : map₂ (· - ·) x x = constant (0#width) := by
  funext i
  exact BitVec.sub_self (x i)

theorem sub_zero : map₂ (· - ·) x (constant (0#width)) = x := by
  funext i
  exact BitVec.sub_zero (x i)

theorem sub_eq_add_neg : map₂ (· - ·) x y = map₂ (· + ·) x (map Neg.neg y) := by
  funext i
  exact BitVec.sub_eq_add_neg (x i) (y i)

theorem sub_sub_self : map₂ (· - ·) x (map₂ (· - ·) x y) = y := by
  funext i
  change x i - (x i - y i) = y i
  apply BitVec.sub_eq_iff_eq_add.mpr
  rw [BitVec.add_comm, BitVec.sub_add_cancel]

theorem sub_add_self_left : map₂ (· - ·) x (map₂ (· + ·) x y) = map Neg.neg y := by
  funext i
  change x i - (x i + y i) = -y i
  rw [← BitVec.sub_sub, BitVec.sub_self, BitVec.zero_sub]

theorem sub_add_self_right : map₂ (· - ·) x (map₂ (· + ·) y x) = map Neg.neg y := by
  funext i
  change x i - (y i + x i) = -y i
  rw [BitVec.add_comm (y i) (x i)]
  exact congrFun (sub_add_self_left x y) i

theorem add_sub_self_right : map₂ (· - ·) (map₂ (· + ·) y x) x = y := by
  funext i
  exact BitVec.add_sub_cancel (y i) (x i)

theorem add_sub_self_left : map₂ (· - ·) (map₂ (· + ·) x y) x = y := by
  funext i
  change x i + y i - x i = y i
  rw [BitVec.add_comm (x i) (y i), BitVec.add_sub_cancel]

theorem neg_neg : map Neg.neg (map Neg.neg x) = x := by
  funext i
  exact BitVec.neg_neg

/-- Negating a smaller broadcast operand commutes with its index pullback. -/
theorem sub_broadcast_eq_add_neg {smallRank : Nat} {smallShape : Shape smallRank}
    (broadcastIndex : Index shape → Index smallShape) (v : Tensor smallShape (BitVec width)) :
    map₂ (· - ·) x (reindex broadcastIndex v) =
      map₂ (· + ·) x (reindex broadcastIndex (map Neg.neg v)) := by
  funext i
  exact BitVec.sub_eq_add_neg (x i) (v (broadcastIndex i))

end TensorRewrite.Pilot.Subtract
