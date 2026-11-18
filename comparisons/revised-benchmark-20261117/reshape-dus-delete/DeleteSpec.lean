import Std
set_option autoImplicit false
namespace RevisedBenchmark.DeleteUpdate

/-- Checked row-major reshape on one element type: reject an illegal size change. -/
def checkedReshape (src dst : List Nat) (flat : List Int) : Option (List Int) :=
  if flat.length = src.prod ∧ src.prod = dst.prod then some flat else none

/-- An original [1,n] update at column start 0, with u rows and v columns.
The only output row is overwritten iff the update has a row and covers the column. -/
def original (n u v : Nat) (base : Fin n → Int) (patch : Fin u → Fin v → Int) :=
  checkedReshape [1,n] [n] (List.ofFn fun j : Fin n =>
    if hr : 0 < u then if hc : j.val < v then patch ⟨0,hr⟩ ⟨j.val,hc⟩ else base j else base j)

/-- Generated update shape omits axis zero because the *base* lost its unit axis. -/
def replacement (n u v : Nat) (base : Fin n → Int) (patch : Fin u → Fin v → Int) :
    Option (List Int) := do
  let row ← checkedReshape [u,v] [v] (List.ofFn (fun r : Fin u => List.ofFn (patch r))).flatten
  return row ++ (List.ofFn base).drop v

def Case : Prop := ∀ (n u v : Nat) (_ : 1 < n) (_ : u ≤ 1) (_ : v ≤ n)
    (base : Fin n → Int) (patch : Fin u → Fin v → Int),
    original n u v base patch = replacement n u v base patch
end RevisedBenchmark.DeleteUpdate
