import MergeSpec
set_option autoImplicit false
namespace RevisedBenchmark.Triangle
open MergeAxes (sumOver)
abbrev Array3 := Nat → Nat → Nat → Int

/-- (AB)C first contracts I, then both the AC and BC edges of the triangle. -/
def left (ni nj nk : Nat) (a b c : Array3) (m n p : Nat) :=
  sumOver (List.range nj) fun j => sumOver (List.range nk) fun k =>
    (sumOver (List.range ni) fun i => a m i j * b i k n) * c j k p

/-- A(BC) first contracts K, then both the AB and AC edges. -/
def right (ni nj nk : Nat) (a b c : Array3) (m n p : Nat) :=
  sumOver (List.range ni) fun i => sumOver (List.range nj) fun j =>
    a m i j * (sumOver (List.range nk) fun k => b i k n * c j k p)

/-- All paired observations of both nested dots for exact integer data. -/
def Goal := ∀ m n p ni nj nk : Nat, ∀ (a b c : Array3)
    (x : Fin m) (y : Fin n) (z : Fin p), left ni nj nk a b c x y z = right ni nj nk a b c x y z
end RevisedBenchmark.Triangle
