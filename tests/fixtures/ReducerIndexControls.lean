import TensorRewrite

set_option autoImplicit false

open TensorRewrite.Pilot.ReducerIndex

#eval do
  let profiles : List (String × ScatterRoles.Parameter × ScatterRoles.Parameter) :=
    [("00", .current, .current), ("11", .update, .update),
      ("01", .current, .update), ("10", .update, .current)]
  for (name, first, second) in profiles do
    let before := (List.finRange 2).map fun index =>
      (ScatterRoles.before first second ScatterRoles.lhs ScatterRoles.base 0 5 index).toInt
    let after := (List.finRange 2).map fun index =>
      (ScatterRoles.after first second ScatterRoles.lhs ScatterRoles.base 0 5 index).toInt
    IO.println ("REDUCER_INDEX_MODEL family=scatter case=p" ++ name ++ " before=" ++
      String.intercalate "," (before.map toString) ++ " after=" ++
      String.intercalate "," (after.map toString))

/-- Compute the actual narrowed-index Select chain only when its source option/extent guard holds. -/
def gatherProbe (name : String) (width extent threshold : Nat) (value : Int) : IO Unit := do
  let index := BitVec.ofInt width value
  let before := GatherLiterals.originalIndex extent index
  let after := if extent ≤ threshold then GatherLiterals.selectedIndex extent index else before
  IO.println ("REDUCER_INDEX_MODEL family=gather case=" ++ name ++ " before=" ++
    toString before ++ " after=" ++ toString after)

#eval do
  gatherProbe "s8_wrap_zero" 8 129 129 0
  gatherProbe "s8_wrap_negative" 8 129 129 (-1)
  gatherProbe "s8_wrap_max" 8 129 129 127
  gatherProbe "s8_extent128" 8 128 128 127
  gatherProbe "s8_threshold128" 8 129 128 0
  gatherProbe "s8_default4" 8 129 4 0
  gatherProbe "s32_zero" 32 129 129 0
  gatherProbe "s32_high" 32 129 129 200
  gatherProbe "s32_negative" 32 129 129 (-1)
