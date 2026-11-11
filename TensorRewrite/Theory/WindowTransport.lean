module

public import TensorRewrite.Theory.ReductionWindow

/-! Pure state representation changes and singleton tuple packaging for ordered windows. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.WindowTransport

/-- Conjugate the entire scalar reducer across an actual state equivalence. -/
def operation {α β : Type} (equivalence : α ≃ β) (source : α → α → α) : β → β → β :=
  fun first second => equivalence (source (equivalence.symm first) (equivalence.symm second))

/-- A scalar and a one-component indexed tuple carry precisely the same pure state. -/
def singletonEquiv (α : Type) : α ≃ (Fin 1 → α) where
  toFun value := fun _ => value
  invFun tuple := tuple 0
  left_inv _ := rfl
  right_inv tuple := by
    funext index
    have same : index = 0 := Subsingleton.elim _ _
    rw [same]

/-- The scalar reducer obtained by unpacking both arguments and the singleton result. -/
def untupleOperation {α : Type} (source : (Fin 1 → α) → (Fin 1 → α) → (Fin 1 → α)) :
    α → α → α := fun first second => source (fun _ => first) (fun _ => second) 0

end TensorRewrite.Theory.WindowTransport
