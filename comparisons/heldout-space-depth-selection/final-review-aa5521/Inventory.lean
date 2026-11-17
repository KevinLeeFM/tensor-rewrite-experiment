import OtherAxisIntegration
import GoalCandidateGuard
open Lean Elab Command
run_cmd do
  let text ← IO.FS.readFile "comparisons/fixed-tactics-v1/forbidden.json"
  let json ← match Json.parse text with
    | .ok result => pure result
    | .error message => throwError "{message}"
  let names ← ofExcept json.getArr?
  let env ← getEnv
  let mut count := 0
  for item in names do
    let name ← ofExcept item.getStr?
    if env.contains name.toName then
      logInfo s!"INVENTORY_HIT {name}"
      count := count + 1
  logInfo s!"TOTAL_HITS {count}"
