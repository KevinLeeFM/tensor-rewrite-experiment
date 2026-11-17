module
import Proof
import Witnesses
import Guard

open TensorRewrite.Heldout.UnitReverse
open TensorRewrite.Pilot

run_cmd HeldoutOperational.noCampaignProofs
run_cmd HeldoutOperational.exactGoal ``reverse_reshape ``Goal

/-- The accepted theorem has the unchanged frozen proposition. -/
example : Goal := reverse_reshape
#print axioms reverse_reshape
#print axioms Controls.wrong_goal_false

namespace TensorRewrite.Heldout.UnitReverse.EdgeAudit

/-- The scalar shape has no axes, while its tensor still has one logical coordinate. -/
def scalarShape : Shape 0 := Fin.elim0

/-- Insert two unit axes into a scalar, without silently requiring positive rank. -/
def scalarPlan : UnitInsertion scalarShape (fun _ : Fin 2 => 1) where
  keptAxis := Fin.elim0
  increasing := by decide
  extent := by decide
  insertedUnit := by decide

/-- Scalar source coordinates are inhabited. -/
example : Nonempty (Index scalarShape) := ⟨Fin.elim0⟩

/-- The theorem applies to actual scalar insertion plans. -/
example (x : Tensor scalarShape Nat) (axes : Fin 2 → Bool) :
    Tensor.reverse axes (reshape scalarPlan x) =
      reshape scalarPlan (Tensor.reverse (remappedAxes scalarPlan axes) x) :=
  reverse_reshape Nat 0 2 scalarShape (fun _ => 1) scalarPlan axes x

/-- A zero-sized retained input axis. -/
def emptyShape : Shape 1 := fun _ => 0

/-- Insert a leading unit axis before a retained zero extent. -/
def emptyPlan : UnitInsertion emptyShape (fun j : Fin 2 => if j.val = 0 then 1 else 0) where
  keptAxis := fun _ => ⟨1, by decide⟩
  increasing := by decide
  extent := by decide
  insertedUnit := by decide

/-- There are no valid input indices on the zero extent. -/
example : ¬ Nonempty (Index emptyShape) := by
  intro ⟨index⟩
  exact Fin.elim0 (index ⟨0, by decide⟩)

/-- The equality remains well typed for the legitimately empty coordinate domain. -/
example (x : Tensor emptyShape Nat) (axes : Fin 2 → Bool) :
    Tensor.reverse axes (reshape emptyPlan x) =
      reshape emptyPlan (Tensor.reverse (remappedAxes emptyPlan axes) x) :=
  reverse_reshape Nat 1 2 emptyShape (fun j => if j.val = 0 then 1 else 0) emptyPlan axes x

end TensorRewrite.Heldout.UnitReverse.EdgeAudit
