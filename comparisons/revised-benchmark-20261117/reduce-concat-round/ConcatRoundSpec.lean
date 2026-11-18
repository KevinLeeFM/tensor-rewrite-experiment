import RadixSpec

set_option autoImplicit false

namespace RevisedBenchmark.ReduceConcat
open RevisedBenchmark.RadixIota (r32)

/-- Strict binary32 addition on represented nonnegative integers in this bounded profile. -/
def add32 (a b : Nat) : Nat := r32 (a + b)

def reduce32 (xs : List Nat) : Nat := xs.foldl add32 0

def original (a b c d : Nat) : Nat := reduce32 ([a,b] ++ [c,d])

def replacement (a b c d : Nat) : Nat := add32 (reduce32 [a,b]) (reduce32 [c,d])

/-- The bound makes every input exactly representable; all intermediate exponents are finite. -/
def StrictCase : Prop := ∀ a b c d : Nat,
  a ≤ 2^24 → b ≤ 2^24 → c ≤ 2^24 → d ≤ 2^24 →
    original a b c d = replacement a b c d

end RevisedBenchmark.ReduceConcat
