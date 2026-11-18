import RadixSpec
set_option autoImplicit false
namespace RevisedBenchmark.WindowFullF32
open RadixIota (r32)

/-- Positive integer-valued F32 entries, including +0, decoded at the selected
rank-one parameter coordinate. Out of bounds this total accessor is unused. -/
def load (xs : List Nat) (i : Nat) := r32 (xs[i]?.getD 0)

/-- The original full window has one legal output and starts at its position.
IterateThroughWindow iterates the rank-one sample coordinates in order. -/
def window (xs : List Nat) (out : Fin 1) :=
  (List.range xs.length).foldl (fun acc k => r32 (acc + load xs (out.val+k))) 0

/-- With at most 512 entries of at most 2^24, this one chunk's nonnegative
integer sum fits exactly in binary64. Reduce narrows its scalar result to F32.
Reshaping that scalar to [1] supplies it at the sole output coordinate. -/
def reshapedFast (xs : List Nat) (_out : Fin 1) :=
  let chunk := (List.range xs.length).foldl (fun sum i => sum + load xs i) 0
  r32 (0 + chunk)

def Goal := ∀ (xs : List Nat), 2 ≤ xs.length → xs.length ≤ 512 →
  (∀ n ∈ xs, n ≤ 2^24) → ∀ out : Fin 1, window xs out = reshapedFast xs out
end RevisedBenchmark.WindowFullF32
