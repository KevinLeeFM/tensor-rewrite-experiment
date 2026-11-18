import HalfSpec
namespace RevisedBenchmark.HalfFactor

private theorem periodic (k : Nat) : half k = 2*(k/4) + half (k%4) := by
  simp only [half, Nat.mod_mod]
  split <;> omega

private theorem shift (k q : Nat) : half (4*q+k) = 2*q+half k := by
  simp only [half, Nat.mul_comm 4 q]
  have h : (q*4+k)%4 = k%4 := by omega
  rw [h]
  split <;> omega

theorem criterion (l r : Bool) (a b : Nat) :
    old l r a b = newValue a b ↔ ResiduesAgree a b := by
  simp only [old,mulHalf,ite_self,newValue,ResiduesAgree]
  have decomp : a+b = 4*(a/4+b/4)+(a%4+b%4) := by omega
  rw [decomp, shift, periodic a, periodic b]
  omega

theorem refuted (l r : Bool) : ¬ Preserves l r := by
  intro claimed
  exact (by unfold ResiduesAgree; decide : ¬ ResiduesAgree 1 1) ((criterion l r 1 1).mp (claimed 1 1))
#print axioms criterion
#print axioms refuted
end RevisedBenchmark.HalfFactor
