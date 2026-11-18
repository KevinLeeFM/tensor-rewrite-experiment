import Std
namespace RevisedBenchmark.HalfFactor
/-- Nonnegative binary32 subnormal quanta. Halfway ties choose the even integer. -/
def half (k : Nat) := k/2 + (if k%4 = 3 then 1 else 0)
def mulHalf (constantOnLeft : Bool) (k : Nat) :=
  if constantOnLeft then half k else half k
def old (left right : Bool) (a b : Nat) := mulHalf left a + mulHalf right b
def newValue (a b : Nat) := half (a+b)
def Preserves (l r : Bool) := ∀ (a b : Fin (2^21)), old l r a.val b.val = newValue a.val b.val

/-- Residue-only test on the low two bits of each input. -/
def ResiduesAgree (a b : Nat) := half (a%4) + half (b%4) = half (a%4 + b%4)
end RevisedBenchmark.HalfFactor
