module
public import Std
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ScalarConcatSlice

/-- Positive-stride half-open slice length. The zero and invalid intervals are empty. -/
def extent (lo hi k : Nat) : Nat :=
  if lo < hi then (hi - lo - 1) / k + 1 else 0

/-- Rank-one logical values in output order. Lookup failure is omitted;
    the theorem separately certifies legality and the actual singleton length. -/
def slice {α : Type} (xs : List α) (lo hi k : Nat) : List α :=
  (List.range (extent lo hi k)).filterMap fun i => xs[lo + i * k]?

/-- Skip whole operands until the first strict endpoint; retain its local start. -/
def locate {α : Type} : List (List α) → Nat → Option (List α × Nat)
  | [], _ => none
  | b :: bs, start => if start < b.length then some (b,start)
                      else locate bs (start - b.length)

/-- Both constructions of the scalar concat-slice helper. Shape compatibility
    implies a one-element operand, while fallback also permits such an operand. -/
def Case : Prop := ∀ {α : Type} (bs : List (List α)) (lo hi k : Nat),
  0 < k → hi ≤ bs.flatten.length → extent lo hi k = 1 →
  ∃ (b : List α) (j : Nat), locate bs lo = some (b,j) ∧ j < b.length ∧
    (slice bs.flatten lo hi k).length = 1 ∧
    slice bs.flatten lo hi k = slice b j (j+1) k ∧
    (b.length = 1 → slice bs.flatten lo hi k = b)
end RevisedBenchmark.ScalarConcatSlice
