import TensorRewrite

set_option autoImplicit false

open TensorRewrite.Pilot
open TensorRewrite.Pilot.DependencyOrder

-- The unconstrained replacement admits a reverse order; the diagnostic edge excludes it.
example : ControlOrder.replacement.IsSchedule [0, 2, 1, 3] :=
  ControlOrder.replacement_reverse_valid

example : ¬ ControlOrder.repaired.IsSchedule [0, 2, 1, 3] := by
  unfold Graph.IsSchedule
  decide

example : ControlOrder.repaired.IsSchedule [0, 1, 2, 3] :=
  ControlOrder.repaired_forward_valid

-- General trace inclusion is about the same finite node set and fixed labels.
example (trace : List String) (valid : ControlOrder.repaired.IsTrace
    ControlOrder.replacementLabels trace) :
    ControlOrder.replacement.IsTrace ControlOrder.replacementLabels trace :=
  Graph.isTrace_of_predecessor_inclusion ControlOrder.replacement ControlOrder.repaired
    (by decide) ControlOrder.replacementLabels trace valid

/-- Executable finite schedule check using the transparent prerequisite definition. -/
def checkSchedule {nodes : Nat} (graph : Graph nodes) (order : List (Fin nodes)) : Bool :=
  @decide (graph.IsSchedule order) (by unfold Graph.IsSchedule; infer_instance)

#eval IO.println ("ORDER_REPAIR_MODEL reverse_before=" ++
  toString (checkSchedule ControlOrder.replacement [0, 2, 1, 3]) ++
  " reverse_after=" ++ toString (checkSchedule ControlOrder.repaired [0, 2, 1, 3]) ++
  " forward_after=" ++ toString (checkSchedule ControlOrder.repaired [0, 1, 2, 3]))
