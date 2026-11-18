import ExchangeProof
open RevisedBenchmark.Exchange
#check (gatherCase : GatherCase)
#check (exchangeCase : ExchangeCase)
#print axioms gatherCase
#print axioms exchangeCase
example : gather (g := 2) (k := 2) (fun r i (_ : Unit) => 10*r.val+i.val) 0 3 () = 11 := by decide
example : exchange (g := 2) (k := 2) (fun r i (_ : Unit) => 10*r.val+i.val) 1 0 () = 2 := by decide
example : exchange (g := 2) (k := 2) (fun r i (_ : Unit) => 10*r.val+i.val) 0 2 () = 10 := by decide
example : ¬ Agreement 2 2 Unit Nat Fin.val := by
  rintro (h | h | h)
  · contradiction
  · exact h ⟨()⟩
  · have e := h 0 1
    contradiction
example : Agreement 2 0 Unit Nat Fin.val := Or.inl rfl
example : Agreement 2 2 Empty Nat Fin.val := Or.inr (Or.inl (fun ⟨c⟩ => nomatch c))
example (g k : Nat) (v : Nat) : Agreement g k Unit Nat (fun _ => v) := Or.inr (Or.inr (fun _ _ => rfl))
