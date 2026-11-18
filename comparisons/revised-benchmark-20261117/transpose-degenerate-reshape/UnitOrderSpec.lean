import Std
namespace RevisedBenchmark.UnitOrder

def visible (size : Nat → Nat) (axes : List Nat) := axes.filter (fun i => size i != 1)
def ordinal (size digit : Nat → Nat) (axes : List Nat) (start : Nat := 0) :=
  axes.foldl (fun acc i => acc * size i + digit i) start

/-- Input axes are numbered in logical order. Output position j refers to input
axis perm[j]. Digits are named by their input axis. -/
def Goal := ∀ (rank : Nat) (perm : List Nat) (size digit : Nat → Nat),
    perm.Perm (List.range rank) →
    (∃ i ∈ perm, size i = 1) → (visible size perm).Pairwise (· ≤ ·) →
    (∀ i ∈ perm, digit i < size i) →
    ∀ (α : Type) (data : Nat → α),
      data (ordinal size digit (List.range rank)) = data (ordinal size digit perm)
end RevisedBenchmark.UnitOrder
