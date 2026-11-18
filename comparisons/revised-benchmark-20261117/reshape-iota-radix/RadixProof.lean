import RadixSpec
set_option autoImplicit false
namespace RevisedBenchmark.RadixIota
private theorem loopValue (w : Nat) (ds : List Digit) (s : Nat) (acc : BitVec w) :
    loop w ds s acc = acc + BitVec.ofNat w (s * linear ds) := by
  induction ds generalizing s acc with
  | nil => simp [loop, linear, BitVec.add_zero]
  | cons d ds ih =>
    rw [loop, ih]
    rw [linear, Nat.mul_add, ← Nat.mul_assoc, Nat.mul_comm s d.index.val]
    simp only [BitVec.ofNat_add, BitVec.ofNat_mul, BitVec.add_assoc]

theorem words : WordCase := by
  intro w d ds
  rw [loopValue, linear, BitVec.ofNat_add]

theorem rounded_counterexample : ¬ FloatCase := by
  intro h
  have eq := h 2 16777217 (by decide) (by decide) (by decide) 1 1
  exact (by decide : (floating 2 16777217 1 1).1 ≠ (floating 2 16777217 1 1).2) eq
example : WordCase := words
example : ¬ FloatCase := rounded_counterexample
#print axioms words
#print axioms rounded_counterexample
end RevisedBenchmark.RadixIota
