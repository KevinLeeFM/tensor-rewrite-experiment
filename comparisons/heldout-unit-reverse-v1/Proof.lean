module

public import Spec
import Guard

public section
set_option autoImplicit false
namespace TensorRewrite.Heldout.UnitReverse
open Pilot

theorem reverse_reshape : Goal := by
  intro α n m s t p axes input
  funext index
  change input (project p (Tensor.reverseIndex axes index)) =
    input (Tensor.reverseIndex (remappedAxes p axes) (project p index))
  apply congrArg input
  funext i
  apply Fin.ext
  change (if axes (p.keptAxis i) then (index (p.keptAxis i)).rev
      else index (p.keptAxis i)).val =
    (if (if s i = 1 then false else axes (p.keptAxis i)) then
      (Fin.cast (p.extent i) (index (p.keptAxis i))).rev
      else Fin.cast (p.extent i) (index (p.keptAxis i))).val
  by_cases unit : s i = 1
  · have hz : (index (p.keptAxis i)).val = 0 := by
      have hb := (index (p.keptAxis i)).isLt
      have he := p.extent i
      omega
    cases axes (p.keptAxis i) <;>
      simp [unit, Fin.rev, Fin.cast, hz, p.extent]
  · cases axes (p.keptAxis i) <;>
      simp [unit, Fin.rev, Fin.cast, p.extent]

end TensorRewrite.Heldout.UnitReverse

#print axioms TensorRewrite.Heldout.UnitReverse.reverse_reshape
run_cmd HeldoutOperational.noCampaignProofs
run_cmd HeldoutOperational.exactGoal ``TensorRewrite.Heldout.UnitReverse.reverse_reshape ``TensorRewrite.Heldout.UnitReverse.Goal
