import BroadcastDotProof

set_option autoImplicit false

namespace RevisedBenchmark.BroadcastDot

/-- A comparison calculation contracts axis 0 of the reduced partner. -/
def aligned {m n : Nat} (fromRight : Bool) (x : Fin n → Int)
    (y : Fin m → Fin n → Fin n → Int) (free : Fin n) : Int :=
  sumAxis fun (k : Fin n) => product fromRight (x k) (reduceFirst y k free)

example : ∀ side : Bool, original side vector partner 1 = 10 ∧
    replacement side vector partner 1 = 0 := by decide
example : ∀ (side : Bool) (free : Fin 2),
    original side vector partner free = aligned side vector partner free := by decide
example : ∀ side : Bool, original side vector partner 0 = replacement side vector partner 0 := by decide
example : admitted 4 2 ∧ ¬ admitted 2 2 ∧ ¬ admitted 0 2 ∧ ¬ admitted 4 0 := by unfold admitted; decide

example : ∀ side : Bool, ¬ Law side := verified
end RevisedBenchmark.BroadcastDot
