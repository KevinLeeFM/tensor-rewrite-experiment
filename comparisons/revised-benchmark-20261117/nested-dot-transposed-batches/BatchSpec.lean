import NestedSpec
namespace RevisedBenchmark.BatchDot
open NestedDot
abbrev A := Nat → Matrix
abbrev B := Nat → Nat → Matrix
abbrev C := Nat → Matrix
abbrev Arr := Nat → Nat → Nat → Nat → Option Nat
def ab_c (k n : Nat) (a : A) (b : B) (c : C) : Arr :=
  fun z x i j => left k n (a x) (b x z) (c z) i j
def a_bc (k n : Nat) (a : A) (b : B) (c : C) : Arr :=
  fun x i z j => right k n (a x) (b x z) (c z) i j

def toLeft (v : Arr) : Arr := fun z x i j => v x i z j
def toRight (v : Arr) : Arr := fun x i z j => v z x i j
def Goal (lhsInner : Bool) := ∀ X Z m k n p : Nat, 0 < k → 0 < n →
  (if lhsInner then X*Z*leftCost m k n p > 2*(X*Z*rightCost m k n p)
   else X*Z*rightCost m k n p > 2*(X*Z*leftCost m k n p)) →
  ∀ (a : A) (b : B) (c : C) (x : Fin X) (z : Fin Z) (i : Fin m) (j : Fin p) (u v : Nat),
    (if lhsInner then ab_c k n a b c z x i j else a_bc k n a b c x i z j) = some u →
    (if lhsInner then toLeft (a_bc k n a b c) z x i j else toRight (ab_c k n a b c) x i z j) = some v →
    u = v
end RevisedBenchmark.BatchDot
