module

public import TensorRewrite.Theory.WindowTupleFamily
public import TensorRewrite.Theory.WindowTransportProof

/-! Universal soundness and exact enumeration of the declared singleton-tuple value family. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.WindowTupleFamily

open Pilot

/-- The declared family preserves the tensor tuple at all ranks and modeled window geometries. -/
theorem rewrite_sound {rank : Nat} {α : Type} (rule : Rule) (plan : ReductionWindow.Plan rank)
    (operation : (Fin 1 → α) → (Fin 1 → α) → (Fin 1 → α)) (initial padding : Fin 1 → α)
    (inputs : Fin 1 → Tensor plan.inputShape α) :
    source rule plan operation initial padding inputs =
      target rule plan operation initial padding inputs := by
  cases rule
  funext component output
  have transported := WindowTransport.singleton_reduce plan operation initial padding
    (fun index component => inputs component index)
  exact congrFun (congrFun transported output) component

/-- Every typed rule is present in the measured family enumeration. -/
theorem allRules_complete (rule : Rule) : rule ∈ allRules := by
  cases rule
  simp [allRules]

/-- The family enumeration contains no duplicate rule. -/
theorem allRules_nodup : allRules.Nodup := by decide

end TensorRewrite.Theory.WindowTupleFamily
