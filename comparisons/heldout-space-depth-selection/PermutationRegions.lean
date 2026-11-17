module
public import PermutationCoordinate
/-! Regional axis equations derived from the frozen permutation's offset rule. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.PermutationRegions
open TensorRewrite.Pilot Heldout.SourceFrame

/-- Axes preceding the inserted count axis remain in place. -/
theorem before_moved {rank : Nat} (axes : AxisConditions rank) (d : Fin (rank + 1))
    (before : d.val < axes.moved.val) : (axes.permutation.outputToInput d).val = d.val := by
  have bound := moved_before_split axes
  have diff : d ≠ axes.moved := by
    intro eq
    have h := congrArg Fin.val eq
    omega
  have h := axes.offset d diff
  simp only [show ¬ d.val > axes.moved.val by omega,
    show ¬ d.val > axes.split.val by omega, ite_false, Nat.sub_zero, Nat.add_zero] at h
  exact h

/-- Axes after the moved position through the split shift right by one in output order. -/
theorem between_moved_split {rank : Nat} (axes : AxisConditions rank) (d : Fin (rank + 1))
    (after : axes.moved.val < d.val) (before : d.val ≤ axes.split.val) :
    (axes.permutation.outputToInput d).val + 1 = d.val := by
  have diff : d ≠ axes.moved := by
    intro eq
    have h := congrArg Fin.val eq
    omega
  have h := axes.offset d diff
  simp only [show d.val > axes.moved.val by omega,
    show ¬ d.val > axes.split.val by omega, ite_true, ite_false, Nat.add_zero] at h
  omega

/-- Axes after the split remain in place. -/
theorem after_split {rank : Nat} (axes : AxisConditions rank) (d : Fin (rank + 1))
    (after : axes.split.val < d.val) : (axes.permutation.outputToInput d).val = d.val := by
  have before := moved_before_split axes
  have diff : d ≠ axes.moved := by
    intro eq
    have h := congrArg Fin.val eq
    omega
  have h := axes.offset d diff
  simp only [show d.val > axes.moved.val by omega,
    show d.val > axes.split.val by omega, ite_true] at h
  omega

#print axioms before_moved
#print axioms between_moved_split
#print axioms after_split
end Heldout.PermutationRegions
