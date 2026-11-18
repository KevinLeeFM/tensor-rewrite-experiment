import ZeroSpec
namespace RevisedBenchmark.PartialAdd
open RevisedBenchmark.NegatedReduction

structure Window (n m : Nat) where
  fits : m ≤ n
  start : Int

def origin {n m : Nat} (w : Window n m) := min (n-m) w.start.toNat

def locate {n m : Nat} (w : Window n m) (i : Fin n) : Option (Fin m) :=
  if h : origin w ≤ i.val ∧ i.val - origin w < m then some ⟨_, h.2⟩ else none

def original {n m : Nat} (w : Window n m) (first : Bool) (base : Fin n → Bool)
    (patch : Fin m → Bool) (i : Fin n) :=
  let v := ((locate w i).map patch).getD false
  bits (if first then plus v (base i) else plus (base i) v)

def replacement {n m : Nat} (w : Window n m) (base : Fin n → Bool)
    (patch : Fin m → Bool) (i : Fin n) :=
  bits (match locate w i with | none => base i | some j => plus (base i) (patch j))

def Preserves (first : Bool) := ∀ n m (w : Window n m) base patch,
  original w first base patch = replacement w base patch
end RevisedBenchmark.PartialAdd
