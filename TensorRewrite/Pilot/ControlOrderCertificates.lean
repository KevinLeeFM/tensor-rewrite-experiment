module

public import TensorRewrite.Pilot.DependencyOrderLemmas

/-! Concrete order countermodel for forwarding And(A,false) to false while
relaying its control successor B. Node IDs follow the archived native witness.
This proves graph-order facts, not an extraction theorem for the C++ pass. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.ControlOrder

open DependencyOrder

/-- Original nodes: false=0, effect A=1, And=2, effect B=3, tuple root=4. -/
def original : Graph 5 where
  predecessors := fun node => match node.val with
    | 2 => [1, 0]
    | 3 => [2]
    | 4 => [2, 3]
    | _ => []

/-- Replacement nodes: false=0, effect A=1, effect B=2, tuple root=3. -/
def replacement : Graph 4 where
  predecessors := fun node => match node.val with
    | 2 => [0]
    | 3 => [0, 2]
    | _ => []

/-- Event labels on the original graph; pure instructions emit nothing. -/
def originalLabels (node : Fin 5) : Option String :=
  if node.val = 1 then some "A" else if node.val = 3 then some "B" else none

/-- The same event labels after forwarding and deleting the pure And node. -/
def replacementLabels (node : Fin 4) : Option String :=
  if node.val = 1 then some "A" else if node.val = 2 then some "B" else none

/-- The original graph admits the forward schedule. -/
theorem original_forward_valid : original.IsSchedule [0, 1, 2, 3, 4] := by
  unfold Graph.IsSchedule
  decide

/-- Every original valid schedule executes effect A before effect B. -/
theorem original_requires_forward (order : List (Fin 5)) (valid : original.IsSchedule order) :
    order.idxOf 1 < order.idxOf 3 :=
  Nat.lt_trans (valid.2.2.2 2 1 (by decide)) (valid.2.2.2 3 2 (by decide))

/-- An original schedule cannot reverse these two effects. -/
theorem original_reverse_impossible (order : List (Fin 5)) (valid : original.IsSchedule order) :
    ¬ order.idxOf 3 < order.idxOf 1 :=
  Nat.not_lt_of_ge (Nat.le_of_lt (original_requires_forward order valid))

/-- The replacement graph admits a schedule with effect B before effect A. -/
theorem replacement_reverse_valid : replacement.IsSchedule [0, 2, 1, 3] := by
  unfold Graph.IsSchedule
  decide

/-- The admitted replacement schedule reverses the two visible event labels. -/
theorem replacement_reverse_trace : eventTrace replacementLabels [0, 2, 1, 3] = ["B", "A"] := by
  rfl

/-- The concrete original forward schedule emits the opposite event order. -/
theorem original_forward_trace : eventTrace originalLabels [0, 1, 2, 3, 4] = ["A", "B"] := by
  rfl

/-- A reverse order is newly admissible in the replacement graph. -/
theorem replacement_admits_reverse :
    ∃ order, replacement.IsSchedule order ∧ order.idxOf 2 < order.idxOf 1 :=
  ⟨[0, 2, 1, 3], replacement_reverse_valid, by decide⟩

/-- Test-only repair: require A before B in addition to the replacement's prerequisites. -/
def repaired : Graph 4 where
  predecessors := fun node => match node.val with
    | 2 => [0, 1]
    | 3 => [0, 2]
    | _ => []

/-- The added prerequisite permits the original forward event order. -/
theorem repaired_forward_valid : repaired.IsSchedule [0, 1, 2, 3] := by
  unfold Graph.IsSchedule
  decide

/-- Every repaired schedule must execute A before B. -/
theorem repaired_requires_forward (order : List (Fin 4)) (valid : repaired.IsSchedule order) :
    order.idxOf 1 < order.idxOf 2 := valid.2.2.2 2 1 (by decide)

/-- The diagnostic repair excludes a reversed actor order. -/
theorem repaired_reverse_impossible (order : List (Fin 4)) (valid : repaired.IsSchedule order) :
    ¬ order.idxOf 2 < order.idxOf 1 :=
  Nat.not_lt_of_ge (Nat.le_of_lt (repaired_requires_forward order valid))

/-- The diagnostic repair adds constraints without adding schedules. -/
theorem repaired_refines_replacement (order : List (Fin 4)) (valid : repaired.IsSchedule order) :
    replacement.IsSchedule order :=
  Graph.isSchedule_of_predecessor_inclusion replacement repaired (by decide) order valid

/-- The repaired graph retains a schedule with the forward observable trace. -/
theorem repaired_forward_trace : repaired.IsTrace replacementLabels ["A", "B"] :=
  ⟨[0, 1, 2, 3], repaired_forward_valid, rfl⟩

end TensorRewrite.Pilot.ControlOrder
