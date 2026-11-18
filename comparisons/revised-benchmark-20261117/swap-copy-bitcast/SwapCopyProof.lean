import SwapCopySpec
set_option autoImplicit false
namespace RevisedBenchmark.SwapCopyBitcast
open CopyChain

private theorem maps {α : Type} {n : Nat} (hn : 0<n) (s c b d : Bool) (x : Fin (n*n) → α) :
    copy (view hn (remap c b s)) (view hn d) x =
      copy (view hn b) (view hn d) (copy (view hn s) (view hn c) x) ∧
    copy (view hn s) (view hn (remap b c d)) x =
      copy (view hn b) (view hn d) (copy (view hn s) (view hn c) x) := by
  cases s <;> cases c <;> cases b <;> cases d <;> constructor <;> funext i <;>
    simp [remap,copy,view,sw,(row hn).decode_encode]

theorem verified : Goal := by
  intro k
  dsimp only
  constructor
  · intro pos t
    cases t
    · simp [tiledOffset,tile,Nat.mul_comm] <;> omega
    · simp only [tiledOffset,tile,ite_true,Nat.mul_div_cancel_left _ (by decide : 0<2)]
      rw [Nat.add_mul, Nat.mul_comm (pos.2.val/2) 2, Nat.add_assoc, Nat.div_add_mod]
      ac_rfl
  · intro α s c b d _ choice x
    unfold emitted old
    by_cases g : valid b s = true
    · simp [g]
      exact (maps _ _ _ _ _ _).1
    · have h := choice.resolve_left g
      simp [g,h]
      exact (maps _ _ _ _ _ _).2

#print axioms verified
end RevisedBenchmark.SwapCopyBitcast
