module
public import TensorRewrite.Pilot.FiniteProduct
/-! Generic associativity of packed finite coordinates; no rewrite-specific facts. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.ProductAssociation
open TensorRewrite.Pilot.FiniteProduct

/-- Packing three axes is independent of whether the first or last pair is merged. -/
theorem join_associate {a b c : Nat} (x : Fin a) (y : Fin b) (z : Fin c) :
    Fin.cast (Nat.mul_assoc a b c) (join (join x y) z) = join x (join y z) := by
  apply Fin.ext
  simp only [Fin.val_cast, join, Nat.add_mul, Nat.mul_assoc, Nat.add_assoc]

/-- The first and last axes of an admitted packed triple cannot have zero extents. -/
theorem no_packed_zero_left (b c : Nat) : ¬ Nonempty (Fin ((0 * b) * c)) := by
  intro ⟨p⟩
  exact Fin.elim0 (by simpa using p)

theorem no_packed_zero_middle (a c : Nat) : ¬ Nonempty (Fin ((a * 0) * c)) := by
  intro ⟨p⟩
  exact Fin.elim0 (by simpa using p)

theorem no_packed_zero_right (a b : Nat) : ¬ Nonempty (Fin ((a * b) * 0)) := by
  intro ⟨p⟩
  exact Fin.elim0 (by simpa using p)

#print axioms join_associate
#print axioms no_packed_zero_left
#print axioms no_packed_zero_middle
#print axioms no_packed_zero_right
end Heldout.ProductAssociation
