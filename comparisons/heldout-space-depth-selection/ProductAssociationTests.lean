module
import ProductAssociation
open TensorRewrite.Pilot.FiniteProduct Heldout.ProductAssociation
set_option autoImplicit false

/-- Nonempty first, interior and last packed coordinates. -/
example : (join (join (⟨0, by decide⟩ : Fin 2) (⟨0, by decide⟩ : Fin 3)) (⟨0, by decide⟩ : Fin 4)).val = 0 := by decide
example : (join (join (⟨1, by decide⟩ : Fin 2) (⟨1, by decide⟩ : Fin 3)) (⟨2, by decide⟩ : Fin 4)).val = 18 := by decide
example : (join (join (⟨1, by decide⟩ : Fin 2) (⟨2, by decide⟩ : Fin 3)) (⟨3, by decide⟩ : Fin 4)).val = 23 := by decide
example : (join (join (⟨0, by decide⟩ : Fin 1) (⟨1, by decide⟩ : Fin 2)) (⟨1, by decide⟩ : Fin 2)).val = 3 := by decide
example : ¬ Nonempty (Fin ((0 * 3) * 4)) := no_packed_zero_left 3 4
example : ¬ Nonempty (Fin ((2 * 0) * 4)) := no_packed_zero_middle 2 4
example : ¬ Nonempty (Fin ((2 * 3) * 0)) := no_packed_zero_right 2 3
/-- Swapping count and the neighboring coordinate is not a valid reassociation. -/
example : (join (join (⟨1, by decide⟩ : Fin 2) (⟨0, by decide⟩ : Fin 3)) (⟨0, by decide⟩ : Fin 4)).val ≠
    (join (join (⟨0, by decide⟩ : Fin 3) (⟨1, by decide⟩ : Fin 2)) (⟨0, by decide⟩ : Fin 4)).val := by decide
