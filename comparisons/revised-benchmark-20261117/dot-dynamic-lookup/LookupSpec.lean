import TensorRewrite.Pilot.DynamicIndexBounds
set_option autoImplicit false
namespace RevisedBenchmark.DotLookup
open TensorRewrite.Pilot.DynamicIndex
def atSlice {n w : Nat} (fits : w ≤ n) (s : Int) (i : Fin w) : Fin n :=
  let z := clampStart n w s + (i.val : Int)
  have h := coordinate_bounds n w fits s i.val (by omega) (by exact_mod_cast i.isLt)
  ⟨z.toNat,(Int.toNat_lt h.1).mpr h.2⟩

/-- Dot at the two free coordinates; order of the two scalar operands follows the side. -/
def dot {k : Nat} (right : Bool) (a b : Fin k → Int) : Int :=
  (List.ofFn fun t => if right then b t * a t else a t * b t).sum
def orig {m n k : Nat} (hm : 1 ≤ m) (right contractFirst : Bool) (s0 s1 : Int)
    (x : Fin m → Fin k → Int) (y : Fin n → Fin k → Int) (u : Fin 1) (j : Fin n) :=
  let selected := atSlice hm (if contractFirst then s1 else s0) u
  let full := atSlice (Nat.le_refl k) (if contractFirst then s0 else s1)
  dot right (fun t => x selected (full t)) (y j)
def repl {m n k : Nat} (hm : 1 ≤ m) (right contractFirst : Bool) (s0 s1 : Int)
    (x : Fin m → Fin k → Int) (y : Fin n → Fin k → Int) (u : Fin 1) (j : Fin n) :=
  let freeStart := if contractFirst then s1 else s0
  let fullStart := if contractFirst then s0 else s1
  let starts := if right then (fullStart,freeStart) else (freeStart,fullStart)
  if right then
    let memo := fun (q : Fin n) (p : Fin m) => dot true (x p) (y q)
    memo (atSlice (Nat.le_refl n) starts.1 j) (atSlice hm starts.2 u)
  else
    let memo := fun (p : Fin m) (q : Fin n) => dot false (x p) (y q)
    memo (atSlice hm starts.1 u) (atSlice (Nat.le_refl n) starts.2 j)
def Case : Prop := ∀ (m n k : Nat) (hm : 1 ≤ m) (right contractFirst : Bool)
    (s0 s1 : Int) (x : Fin m → Fin k → Int) (y : Fin n → Fin k → Int),
    orig hm right contractFirst s0 s1 x y = repl hm right contractFirst s0 s1 x y
end RevisedBenchmark.DotLookup
