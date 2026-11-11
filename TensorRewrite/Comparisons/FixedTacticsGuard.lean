module

public import TensorRewrite.Comparisons.FixedTacticsPolicies
public import Lean.Meta.Basic

/-! Operational audits for the fixed-tactic comparison. These commands do not construct proofs. -/

public meta section

namespace TensorRewrite.Comparisons.FixedTactics

open Lean Elab Command Meta

/-- Load frozen comparison metadata; malformed JSON stops the audit. -/
def readJson (path : String) : CommandElabM Json := do
  let content ← IO.FS.readFile path
  match Json.parse content with
  | .ok result => pure result
  | .error message => throwError "Invalid comparison JSON: {message}"

/-- Reject every registered campaign proof in the imported baseline environment. -/
def noCampaignProofs : CommandElabM Unit := do
  let values ← readJson "comparisons/fixed-tactics-v1/forbidden.json"
  let names ← ofExcept values.getArr?
  let environment ← getEnv
  for value in names do
    let name ← ofExcept value.getStr?
    if environment.contains name.toName then
      throwError "FIXED_BASELINE_LEAK: {name}"
  logInfo ("FIXED_BASELINE_GUARD absent=" ++ toString names.size ++ " present=0")

/-- Compare a restated proposition with the original declaration's fully elaborated type. -/
def sameStatement (original statement : Name) : CommandElabM Unit := do
  liftTermElabM do
    let originalValue ← mkConstWithFreshMVarLevels original
    let actual ← inferType originalValue
    let expected ← whnf (← mkConstWithFreshMVarLevels statement)
    unless ← isDefEq actual expected do
      throwError "FIXED_BASELINE_SIGNATURE_MISMATCH: {original} versus {statement}"

/-- Verify exact statement fidelity for every selected reviewed target. -/
def allStatements : CommandElabM Unit := do
  let document ← readJson "comparisons/fixed-tactics-v1/targets.json"
  let values ← ofExcept (document.getObjValAs? (Array Json) "targets")
  for value in values do
    let original ← ofExcept (value.getObjValAs? String "original")
    let statement ← ofExcept (value.getObjValAs? String "statement")
    sameStatement original.toName statement.toName
  logInfo ("FIXED_BASELINE_SIGNATURES exact=" ++ toString values.size)

end TensorRewrite.Comparisons.FixedTactics
