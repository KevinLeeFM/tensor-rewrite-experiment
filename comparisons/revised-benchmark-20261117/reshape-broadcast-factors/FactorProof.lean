import FactorSpec
namespace RevisedBenchmark.ReshapeBroadcast
theorem suffixes {a b : List Nat} {w : Nat} (m : Match a b w) (same : a.prod = b.prod)
    (flat : Fin b.prod) : m.s.prod = m.t.prod ∧ 0 < w := by
  rcases m with ⟨p,q,s,t,rfl,rfl,h⟩
  have pos : 0 < (q ++ w :: t).prod := Nat.zero_lt_of_lt flat.isLt
  simp only [List.prod_append, List.prod_cons, h, ← Nat.mul_assoc] at same pos
  have pp : 0 < q.prod * w := by
    by_cases h0 : q.prod * w = 0
    · simp [h0] at pos
    · omega
  have pw : 0 < w := by
    by_cases h0 : w = 0
    · simp [h0] at pp
    · omega
  exact ⟨Nat.eq_of_mul_eq_mul_left pp same, pw⟩

theorem verified : Goal := by
  intro m before after width mapping counts flat α data
  apply congrArg data
  funext i
  simp only [(suffixes (mapping i) counts flat).1]

theorem legal_read {a b : List Nat} {w : Nat} (m : Match a b w) (same : a.prod = b.prod)
    (flat : Fin b.prod) : flat.val / m.s.prod % w < w :=
  Nat.mod_lt _ (suffixes m same flat).2
#print axioms verified
#print axioms legal_read
end RevisedBenchmark.ReshapeBroadcast
