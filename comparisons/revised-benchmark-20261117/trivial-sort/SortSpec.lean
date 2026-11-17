module
public import TensorRewrite.Pilot.Tensor
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.TrivialSort
open TensorRewrite.Pilot
/-- A fiber-local rearrangement obtains each output value from a bounded
    position on the sort axis. Every other coordinate is copied literally. -/
def rearrange {r : Nat} {s : Shape r} {α : Type} (axis : Fin r)
    (pick : Index s → Fin (s axis)) (xs : Tensor s α) : Tensor s α :=
  fun j => xs (fun d => if h : axis = d then h ▸ pick j else j d)

/-- One input is returned directly. With at least two inputs the ordered tuple
    is returned; its components use the same within-fiber selection. -/
def Goal : Prop :=
  ∀ {r : Nat} {s : Shape r} (axis : Fin r) (pick : Index s → Fin (s axis)),
    ((∃ d, s d = 0) ∨ s axis ≤ 1) →
    (∀ {α : Type} (xs : Tensor s α), rearrange axis pick xs = xs) ∧
    (∀ {k : Nat} {A : Fin (k+2) → Type} (xs : (c : Fin (k+2)) → Tensor s (A c)),
      (fun c => rearrange axis pick (xs c)) = xs)
end RevisedBenchmark.TrivialSort
