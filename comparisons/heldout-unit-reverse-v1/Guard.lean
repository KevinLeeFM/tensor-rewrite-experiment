module
public import Lean

/-! Operational isolation/type checks; these commands do not construct target proofs. -/
public meta section
namespace HeldoutOperational
open Lean Elab Command Meta

/-- Reject project declarations outside the frozen semantic definitions and this case. -/
def noCampaignProofs : CommandElabM Unit := do
  let allowed := ["TensorRewrite.Pilot.Shape", "TensorRewrite.Pilot.Index",
    "TensorRewrite.Pilot.Tensor", "TensorRewrite.Pilot.Tensor.constant",
    "TensorRewrite.Pilot.Tensor.map", "TensorRewrite.Pilot.Tensor.map₂",
    "TensorRewrite.Pilot.Tensor.reindex", "TensorRewrite.Pilot.Tensor.reverseIndex",
    "TensorRewrite.Pilot.Tensor.reverse", "TensorRewrite.Pilot.Tensor.axisMask",
    "TensorRewrite.Pilot.Tensor.axisMask._proof_1"]
  let env ← getEnv
  for (name, _) in env.constants.toList do
    let s := name.toString
    if s.startsWith "TensorRewrite." &&
        !(s.startsWith "TensorRewrite.Heldout.UnitReverse.") &&
        !(allowed.any fun a => s == a) then
      throwError "HELDOUT_BASELINE_LEAK: {name}"
  logInfo "HELDOUT_BASELINE_GUARD passed"

/-- Require the theorem's elaborated type to be exactly the frozen Goal. -/
def exactGoal (proof goal : Name) : CommandElabM Unit := do
  liftTermElabM do
    let actual ← inferType (← mkConstWithFreshMVarLevels proof)
    let expected ← whnf (← mkConstWithFreshMVarLevels goal)
    unless ← isDefEq actual expected do
      throwError "HELDOUT_SIGNATURE_MISMATCH: {proof} versus {goal}"
  logInfo "HELDOUT_SIGNATURE exact"
end HeldoutOperational
