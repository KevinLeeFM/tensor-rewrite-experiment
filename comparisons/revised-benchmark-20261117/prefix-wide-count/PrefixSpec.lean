import Std
namespace RevisedBenchmark.WideCount

/-- Inclusive one-dimensional prefix of a uniform U64 word with zero seed.
Padding contributes zero; r+1 input positions are in bounds at coordinate r. -/
def original (value : BitVec 64) (r : Nat) :=
  (List.replicate (r+1) value).foldl (· + ·) (0#64)
def replacement (value : BitVec 64) (r : Nat) :=
  let count := BitVec.ofNat 32 r + 1#32
  value * BitVec.ofInt 64 count.toInt
def Goal := ∀ n, 1 < n → ∀ (r : Fin n) (value : BitVec 64),
  original value r.val = replacement value r.val
end RevisedBenchmark.WideCount
