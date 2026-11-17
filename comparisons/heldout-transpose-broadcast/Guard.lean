module
public import Lean
/-! Guard against known campaign-proof imports and check the exact elaborated goal. -/
public meta section
namespace Heldout.TransposeBroadcastGuard
open Lean Elab Command Meta

def noCampaignProofs : CommandElabM Unit := do
  let text ← IO.FS.readFile "comparisons/fixed-tactics-v1/forbidden.json"
  let json ← match Json.parse text with
    | .ok result => pure result
    | .error message => throwError "invalid campaign inventory: {message}"
  let names ← ofExcept json.getArr?
  let env ← getEnv
  for item in names do
    let name ← ofExcept item.getStr?
    if env.contains name.toName then
      throwError "BROADCAST_BASELINE_LEAK: {name}"
  logInfo s!"BROADCAST_BASELINE_GUARD checked={names.size}"

def exactGoal (proof goal : Name) : CommandElabM Unit := do
  liftTermElabM do
    let actual ← inferType (← mkConstWithFreshMVarLevels proof)
    let expected ← whnf (← mkConstWithFreshMVarLevels goal)
    unless ← isDefEq actual expected do
      throwError "BROADCAST_SIGNATURE_MISMATCH: {proof} versus {goal}"
  logInfo "BROADCAST_SIGNATURE exact"
end Heldout.TransposeBroadcastGuard
