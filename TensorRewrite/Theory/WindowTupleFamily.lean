module

public import TensorRewrite.Theory.WindowTransport

/-! A closed pure-value family for singleton tuple windows and scalar replacements. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.WindowTupleFamily

open Pilot

/-- Exactly the singleton tuple rewrite; larger coupled tuples are outside this typed rule. -/
inductive Rule where
  | singleton
deriving DecidableEq, Repr

/-- The complete rule enumeration for this declared family. -/
def allRules : List Rule := [.singleton]

/-- The source returns component tensors through whole-state window semantics. -/
def source {rank : Nat} {α : Type} (_rule : Rule) (plan : ReductionWindow.Plan rank)
    (operation : (Fin 1 → α) → (Fin 1 → α) → (Fin 1 → α)) (initial padding : Fin 1 → α)
    (inputs : Fin 1 → Tensor plan.inputShape α) : Fin 1 → Tensor plan.outputShape α :=
  fun component output => ReductionWindow.reduce plan operation initial padding
    (fun index component => inputs component index) output component

/-- The target wraps the scalar window with the actual untupled reducer/initializer/padding. -/
def target {rank : Nat} {α : Type} (_rule : Rule) (plan : ReductionWindow.Plan rank)
    (operation : (Fin 1 → α) → (Fin 1 → α) → (Fin 1 → α)) (initial padding : Fin 1 → α)
    (inputs : Fin 1 → Tensor plan.inputShape α) : Fin 1 → Tensor plan.outputShape α :=
  fun _ => ReductionWindow.reduce plan (WindowTransport.untupleOperation operation)
    (initial 0) (padding 0) (inputs 0)

end TensorRewrite.Theory.WindowTupleFamily
