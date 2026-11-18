import Std
namespace RevisedBenchmark.RandomShape
/-- Numerator of the point mass for one complete rectangular array, using
independent finite Boolean draws with common nonnegative integer weights. -/
def mass (r c : Nat) (weight : Bool → Nat) (a : Fin r → Fin c → Bool) :=
  ((List.finRange r).map fun i => ((List.finRange c).map fun j => weight (a i j)).prod).prod
def total (r c : Nat) (weight : Bool → Nat) := (weight false + weight true) ^ (r*c)
def Law := ∀ r c (w : Bool → Nat), 0 < w false + w true →
  ∀ b : Fin c → Fin r → Bool,
    (mass r c w (fun i j => b j i), total r c w) = (mass c r w b, total c r w)

def oldReshape {α : Type} (stream : Nat → α) (oldCols newCols i j : Nat) :=
  let k := i * newCols + j
  stream ((k / oldCols) * oldCols + k % oldCols)
def Reshape := ∀ (α : Type) (stream : Nat → α) (r c u v : Nat),
  r*c = u*v → ∀ (i : Fin u) (j : Fin v),
    oldReshape stream c v i.val j.val = stream (i.val*v+j.val)
def SameSeedTranspose := ∀ (stream : Nat → Bool) r c (i : Fin c) (j : Fin r),
  stream (j.val*c+i.val) = stream (i.val*r+j.val)
end RevisedBenchmark.RandomShape
