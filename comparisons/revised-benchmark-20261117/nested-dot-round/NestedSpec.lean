import RadixSpec
set_option autoImplicit false
namespace RevisedBenchmark.NestedDot
open RevisedBenchmark.RadixIota

/-- Partial exact integer-valued binary32 fragment, finite inputs and RNE after every primitive. -/
def rounded (n : Nat) : Option Nat := if n ≤ 2^30 then some (r32 n) else none
abbrev Matrix := Nat → Nat → Option Nat
def loadMat (x : Nat → Nat → Nat) : Matrix := fun i j => rounded (x i j)
def dot (k : Nat) (a b : Matrix) : Matrix := fun i j =>
  (List.range k).foldlM (fun acc t => do
    let x ← a i t
    let y ← b t j
    let prod ← rounded (x*y)
    rounded (acc+prod)) 0
def left (k n : Nat) (a b c : Matrix) := dot n (dot k a b) c
def right (k n : Nat) (a b c : Matrix) := dot k a (dot n b c)
def leftCost (m k n p : Nat) := 2*(m*k*n + m*n*p)
def rightCost (m k n p : Nat) := 2*(k*n*p + m*k*p)

/-- Direct two-matrix-chain reorder, orienting original at the more expensive parenthesization. -/
def Case (leftInner : Bool) : Prop := ∀ (m k n p : Nat),
  0 < k → 0 < n →
  (if leftInner then leftCost m k n p > 2*rightCost m k n p
   else rightCost m k n p > 2*leftCost m k n p) →
  ∀ (a b c : Nat → Nat → Nat) (i : Fin m) (j : Fin p) (l r : Nat),
    left k n (loadMat a) (loadMat b) (loadMat c) i j = some l →
    right k n (loadMat a) (loadMat b) (loadMat c) i j = some r → l = r

end RevisedBenchmark.NestedDot
