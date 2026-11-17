import TensorRewrite.Pilot.Reverse
set_option autoImplicit false
namespace RevisedBenchmark.ReverseMasks
open TensorRewrite.Pilot Tensor
/-- The union-minus-intersection output of the nested-reverse branch, in axis order. -/
def difference {r : Nat} (a b : List (Fin r)) : List (Fin r) :=
  (List.finRange r).filter fun k => (decide (k ∈ a) || decide (k ∈ b)) &&
    !(decide (k ∈ a) && decide (k ∈ b))

def Compose : Prop := ∀ {r : Nat} (s : Shape r) (a b : List (Fin r)) (α : Type) (x : Tensor s α),
  reverse (axisMask b) (reverse (axisMask a) x) = reverse (axisMask (difference a b)) x

def Cancel : Prop := ∀ {r : Nat} (s : Shape r) (a b : List (Fin r)) (α : Type) (x : Tensor s α),
  difference a b = [] → reverse (axisMask b) (reverse (axisMask a) x) = x

def IdentityBoundary : Prop := ∀ {r : Nat} (s : Shape r) (a : List (Fin r)),
  (∀ (α : Type) (x : Tensor s α), reverse (axisMask a) x = x) ↔
  (Nonempty (Index s) → ∀ k ∈ a, s k = 1)

def Binary : Prop := ∀ {r : Nat} (s : Shape r) (a : List (Fin r)) (α : Type)
    (f : α → α → α) (x : Tensor s α) (v : α),
  reverse (axisMask a) (map₂ f (constant v) x) = map₂ f (constant v) (reverse (axisMask a) x) ∧
  reverse (axisMask a) (map₂ f x (constant v)) = map₂ f (reverse (axisMask a) x) (constant v)
end RevisedBenchmark.ReverseMasks
