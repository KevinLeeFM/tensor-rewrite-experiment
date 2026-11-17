module
public import GoalCandidate
public import ContextAssociation
/-! The selected split-count coordinate follows the checked permutation. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.PermutationCoordinate
open TensorRewrite.Pilot Heldout.SpaceDepthCandidate

/-- The checked forward selection determines the corresponding inverse axis. -/
theorem selected_inverse {rank : Nat} (axes : Heldout.SourceFrame.AxisConditions rank) :
    axes.permutation.inputToOutput axes.split.castSucc = axes.moved := by
  rw [← axes.selected, axes.permutation.input_output]

/-- The count axis of the original inner reshape reads the checked moved output axis. -/
theorem count_coordinate {rank : Nat} (axes : Heldout.SourceFrame.AxisConditions rank)
    (inner : Shape (rank + 1)) (index : Index (transposedShape inner axes.permutation)) :
    (Tensor.transposeIndex axes.permutation (transpose_extents inner axes.permutation)
      index axes.split.castSucc).val = (index axes.moved).val := by
  exact congrArg (fun i => (index i).val) (selected_inverse axes)

/-- The width axis stays in its post-split position under the checked move. -/
theorem width_axis_fixed {rank : Nat} (axes : Heldout.SourceFrame.AxisConditions rank) :
    axes.permutation.outputToInput axes.split.succ = axes.split.succ := by
  have before := Heldout.SourceFrame.moved_before_split axes
  have distinct : axes.split.succ ≠ axes.moved := by
    intro eq
    have h := congrArg Fin.val eq
    simp only [Fin.val_succ] at h
    omega
  have h := axes.offset axes.split.succ distinct
  apply Fin.ext
  simp only [Fin.val_succ] at h ⊢
  simp only [show axes.split.val + 1 > axes.moved.val by omega,
    show axes.split.val + 1 > axes.split.val by omega, ite_true] at h
  omega

/-- The corresponding inverse map also fixes the width axis. -/
theorem width_inverse {rank : Nat} (axes : Heldout.SourceFrame.AxisConditions rank) :
    axes.permutation.inputToOutput axes.split.succ = axes.split.succ := by
  calc
    axes.permutation.inputToOutput axes.split.succ =
        axes.permutation.inputToOutput (axes.permutation.outputToInput axes.split.succ) :=
      congrArg axes.permutation.inputToOutput (width_axis_fixed axes).symm
    _ = axes.split.succ := axes.permutation.input_output _

#print axioms width_axis_fixed
#print axioms width_inverse
#print axioms selected_inverse
#print axioms count_coordinate
end Heldout.PermutationCoordinate
