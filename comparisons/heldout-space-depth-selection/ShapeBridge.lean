module
public import Std

/-! Generic independent-axis shape updates; this module states no tensor rewrite. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.ShapeBridge

/-- Replace an extent at one finite axis, preserving all other extents. -/
def setExtent {rank : Nat} (shape : Fin rank → Nat) (axis : Fin rank) (extent : Nat) :
    Fin rank → Nat := fun i => if i = axis then extent else shape i

/-- Replacing different axis extents is independent of update order. -/
theorem setExtent_commute {rank : Nat} (shape : Fin rank → Nat)
    (a b : Fin rank) (different : a ≠ b) (x y : Nat) :
    setExtent (setExtent shape a x) b y = setExtent (setExtent shape b y) a x := by
  funext i
  by_cases ia : i = a
  · subst i
    simp [setExtent, different]
  · by_cases ib : i = b
    · subst i
      simp [setExtent, Ne.symm different]
    · simp [setExtent, ia, ib]

/-- Replacing one axis twice retains the later extent. -/
theorem setExtent_overwrite {rank : Nat} (shape : Fin rank → Nat)
    (a : Fin rank) (x y : Nat) :
    setExtent (setExtent shape a x) a y = setExtent shape a y := by
  funext i
  by_cases ia : i = a <;> simp [setExtent, ia]

#print axioms setExtent_commute
#print axioms setExtent_overwrite
end Heldout.ShapeBridge

namespace Heldout.ShapeBridge
/-- A zero extent on an untouched axis remains zero. -/
example : setExtent (fun _ : Fin 3 => 0) ⟨1, by decide⟩ 5 ⟨0, by decide⟩ = 0 := by decide
/-- Updating two distinct axes agrees in both orders on a concrete nonempty shape. -/
example : setExtent (setExtent (fun _ : Fin 3 => 4) ⟨1, by decide⟩ 2)
    ⟨2, by decide⟩ 3 ⟨1, by decide⟩ = 2 := by decide
/-- Failing to update the intended axis changes the shape. -/
example : setExtent (fun _ : Fin 3 => 4) ⟨1, by decide⟩ 2 ⟨1, by decide⟩ ≠
    setExtent (fun _ : Fin 3 => 4) ⟨2, by decide⟩ 2 ⟨1, by decide⟩ := by decide
end Heldout.ShapeBridge

namespace Heldout.ShapeBridge
/-- A detected split cannot have zero chunks: zero would equal its product. -/
theorem detected_chunks_positive (chunks width : Nat)
    (different : chunks ≠ chunks * width) : 0 < chunks := by
  by_cases h : chunks = 0
  · simp [h] at different
  · omega

/-- The source offset check and finite permutation injectivity force the moved axis left. -/
theorem moved_axis_before_split {rank : Nat} (perm : Fin rank → Fin rank)
    (split moved : Fin rank)
    (injective : ∀ a b, perm a = perm b → a = b)
    (selected : perm moved = split) (different : moved ≠ split)
    (offset : ∀ d, d ≠ moved →
      (perm d).val = d.val - (if d.val > moved.val then 1 else 0) +
        (if d.val > split.val then 1 else 0)) :
    moved.val < split.val := by
  by_cases before : moved.val < split.val
  · exact before
  · have noEarlier : ¬ split.val > moved.val := by omega
    have same := offset split (Ne.symm different)
    simp [noEarlier] at same
    have sameAxis : perm split = split := Fin.ext same
    have equal : split = moved := injective split moved (sameAxis.trans selected.symm)
    exact False.elim (different equal.symm)

#print axioms detected_chunks_positive
#print axioms moved_axis_before_split
end Heldout.ShapeBridge
