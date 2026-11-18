import Std
namespace RevisedBenchmark.DotStrength

/-- Binary16 RNE on nonnegative integers below the overflow binade. -/
def half (v : Nat) :=
  let step := 2 ^ (v.log2 - 10)
  let q := v / step
  let rem := v % step
  (q + if 2*rem > step ∨ (2*rem = step ∧ q % 2 = 1) then 1 else 0) * step

inductive Free where | none | lhs | rhs deriving DecidableEq
def outer (f : Free) := if f = .none then 1 else 2
def left (f : Free) (p : Fin 2 → Fin 2 → Fin 64) (o : Nat) (k : Fin 2) :=
  (p (if f = .lhs ∧ o = 1 then 1 else 0) k).val
def right (f : Free) (p : Fin 2 → Fin 2 → Fin 64) (o : Nat) (k : Fin 2) :=
  (p (if f = .rhs ∧ o = 1 then 1 else 0) k).val

def dot (f : Free) (x w : Fin 2 → Fin 2 → Fin 64) (o : Nat) :=
  half (((List.finRange 2).map fun k => left f x o k * right f w o k).sum)
def reduced (f : Free) (x w : Fin 2 → Fin 2 → Fin 64) (o : Nat) :=
  half (((List.finRange 2).map fun k => half (left f x o k * right f w o k)).sum)
def Goal (f : Free) := ∀ x w, ∀ o : Fin (outer f), dot f x w o.val = reduced f x w o.val
end RevisedBenchmark.DotStrength
