import PartialSpec
namespace RevisedBenchmark.PartialAdd
open RevisedBenchmark.NegatedReduction

theorem agree_iff {n m : Nat} (w : Window n m) (first : Bool) base patch :
    original w first base patch = replacement w base patch ↔
    ∀ i, locate w i = none → base i = false := by
  constructor
  · intro h i outside
    have value := congrFun h i
    cases b : base i <;> cases first <;> simp_all [original, replacement, bits, plus]
  · intro h
    funext i
    cases k : locate w i with
    | none => simp [original, replacement, k, h i k, plus]
    | some j =>
      cases first <;> simp [original, replacement, k, plus, Bool.and_comm]

theorem refuted (first : Bool) : ¬ Preserves first := by
  intro h
  let w : Window 3 1 := ⟨by decide, 1⟩
  have outside := (agree_iff w first (fun _ => true) (fun _ => false)).mp
    (h 3 1 w _ _)
  exact Bool.noConfusion (outside 0 (by decide))

#print axioms agree_iff
#print axioms refuted
end RevisedBenchmark.PartialAdd
