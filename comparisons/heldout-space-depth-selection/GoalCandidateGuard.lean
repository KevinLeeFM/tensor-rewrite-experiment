module
public import Lean

/-! Operational campaign-proof environment guard for the candidate's preproof baseline. -/
public meta section
namespace Heldout.GoalCandidateGuard
open Lean Elab Command Meta

/-- Reject all names in the existing fixed-tactics campaign-proof inventory. -/
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
      throwError "CANDIDATE_BASELINE_LEAK: {name}"
  logInfo s!"CANDIDATE_BASELINE_GUARD checked={names.size}"
/-- Compare an elaborated theorem's type with the candidate proposition. -/
def exactGoal (proof goal : Name) : CommandElabM Unit := do
  liftTermElabM do
    let actual ← inferType (← mkConstWithFreshMVarLevels proof)
    let expected ← whnf (← mkConstWithFreshMVarLevels goal)
    unless ← isDefEq actual expected do
      throwError "CANDIDATE_SIGNATURE_MISMATCH: {proof} versus {goal}"
  logInfo "CANDIDATE_SIGNATURE exact"
end Heldout.GoalCandidateGuard
