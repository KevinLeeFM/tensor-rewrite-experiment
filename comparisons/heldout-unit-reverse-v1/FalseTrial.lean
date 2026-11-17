module
import Witnesses
open TensorRewrite.Heldout.UnitReverse.Controls
-- Expected rejection on a separately kernel-refuted, well-formed proposition.
example : WrongGoal := by unfold WrongGoal; rfl
