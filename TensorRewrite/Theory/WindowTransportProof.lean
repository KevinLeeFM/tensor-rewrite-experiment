module

public import TensorRewrite.Theory.WindowTransportLemmas

/-! State transport preserves every contribution and the actual fold schedule. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.WindowTransport

open Pilot

/-- Singleton-tuple elimination retains the whole reducer and both distinguished state values. -/
theorem singleton_reduce {rank : Nat} {α : Type} (plan : ReductionWindow.Plan rank)
    (source : (Fin 1 → α) → (Fin 1 → α) → (Fin 1 → α)) (initial padding : Fin 1 → α)
    (input : Tensor plan.inputShape (Fin 1 → α)) :
    ReductionWindow.reduce plan source initial padding input =
      Tensor.map (singletonEquiv α)
        (ReductionWindow.reduce plan (untupleOperation source) (initial 0) (padding 0)
          (Tensor.map (fun tuple => tuple 0) input)) := by
  have transported := reduce_equiv plan (singletonEquiv α).symm source initial padding input
  funext output
  have values := congrFun transported output
  change ReductionWindow.reduce plan (untupleOperation source) (initial 0) (padding 0)
    (Tensor.map (fun tuple => tuple 0) input) output =
      (ReductionWindow.reduce plan source initial padding input output) 0 at values
  change _ = fun _ => ReductionWindow.reduce plan (untupleOperation source)
    (initial 0) (padding 0) (Tensor.map (fun tuple => tuple 0) input) output
  rw [values]
  exact ((singletonEquiv α).apply_symm_apply _).symm

end TensorRewrite.Theory.WindowTransport
