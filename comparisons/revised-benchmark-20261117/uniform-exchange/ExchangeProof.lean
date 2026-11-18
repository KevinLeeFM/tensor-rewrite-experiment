import ExchangeSpec
set_option autoImplicit false
namespace RevisedBenchmark.Exchange
private theorem sender_slot {g k : Nat} (r : Fin g) (j : Fin k) : sender (slot r j) = r := by
  apply Fin.ext
  change (r.val*k+j.val)/k = r.val
  have hk : 0 < k := Nat.lt_of_le_of_lt (Nat.zero_le _) j.isLt
  rw [Nat.add_comm, Nat.add_mul_div_right _ _ hk, Nat.div_eq_of_lt j.isLt, Nat.zero_add]

private theorem boundary (g k : Nat) (C A : Type) (v : Fin g → A) :
    ((fun (_ : Fin g) (i : Fin (g*k)) (_ : C) => v (sender i)) =
      (fun r _ _ => v r)) ↔ Agreement g k C A v := by
  constructor
  · intro h
    by_cases hz : k = 0
    · exact Or.inl hz
    by_cases hc : Nonempty C
    · refine Or.inr (Or.inr ?_)
      obtain ⟨c⟩ := hc
      intro a b
      let j : Fin k := ⟨0, by omega⟩
      have eq := congrFun (congrFun (congrFun h b) (slot a j)) c
      change v (sender (slot a j)) = v b at eq
      simpa only [sender_slot] using eq
    · exact Or.inr (Or.inl hc)
  · intro h
    funext r i c
    rcases h with hz | hc | ha
    · subst k
      exact False.elim (by simpa using i.isLt)
    · exact False.elim (hc ⟨c⟩)
    · exact ha _ _

theorem gatherCase : GatherCase := fun g k _ C A v => boundary g k C A v
theorem exchangeCase : ExchangeCase := fun g k _ C A v => boundary g k C A v
end RevisedBenchmark.Exchange
