import Std
set_option autoImplicit false
namespace RevisedBenchmark.LeadingSlice

/-- Minor to major, each triple records source extent, start and width. -/
inductive Box where
  | scalar
  | axis (extent start width : Nat) (outer : Box)
deriving Repr, DecidableEq
def size : Box → Nat
  | .scalar => 1
  | .axis _ _ w b => w * size b
def readPos : Box → Nat → Nat
  | .scalar, _ => 0
  | .axis n lo w b, j => lo + j%w + n*readPos b (j/w)
def build : List Nat → Nat → Nat → Option Box
  | [], p, k => if p = 0 ∧ k = 1 then some .scalar else none
  | n::ns, p, k =>
    if n = 0 then none
    else if n ≤ k then
      if k%n = 0 ∧ p%n = 0 then (build ns (p/n) (k/n)).map (.axis n 0 n) else none
    else if p%n + k ≤ n then (build ns (p/n) 1).map (.axis n (p%n) k) else none

/-- The leading output dimension has width lead, remaining output axes have product tail.prod.
The input axes are listed minor to major. -/
def Case : Prop := ∀ (ns tail : List Nat) (lead s e : Nat) (b : Box)
    (_ : ns.prod = lead*tail.prod) (_ : s ≤ e) (_ : e ≤ lead)
    (_ : build ns (s*tail.prod) ((e-s)*tail.prod) = some b),
    size b = (e-s)*tail.prod ∧ ∀ (α : Type) (x : Nat → α) (j : Fin ((e-s)*tail.prod)),
      readPos b j.val < ns.prod ∧ x (readPos b j.val) = x (s*tail.prod + j.val)
end RevisedBenchmark.LeadingSlice
