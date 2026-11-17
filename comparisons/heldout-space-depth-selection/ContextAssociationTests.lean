module
import ContextAssociation
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.FiniteProduct
  Heldout.ContextAssociation
set_option autoImplicit false

/-- Empty prefix and suffix ranks retain the two middle coordinates. -/
example (x : Fin 2) (y : Fin 3) :
    Fin.cast (congrArg (1 * ·) (Nat.mul_assoc 2 3 1))
      (join (⟨0, by decide⟩ : Fin 1) (join (join x y) (⟨0, by decide⟩ : Fin 1))) =
    join (⟨0, by decide⟩ : Fin 1) (join x (join y (⟨0, by decide⟩ : Fin 1))) :=
  context_associate ⟨0, by decide⟩ x y ⟨0, by decide⟩

/-- Prefix and suffix each contain two axes and are not restricted to singleton extents. -/
def shape : Shape 2 := fun _ => 2
def coords : Index shape := fun i => ⟨1, by simp [shape]⟩
example (x : Fin 2) (y : Fin 3) := shape_context_associate shape shape coords coords x y

/-- A zero axis in either context has no full coordinate, so the theorem is not fed a false index. -/
example : ¬ Nonempty (Index (fun _ : Fin 1 => 0)) := by
  intro ⟨index⟩
  exact Fin.elim0 (index 0)

/-- Nontrivial prefix/suffix coordinates preserve packed order: swapping middle axes changes it. -/
example : (join (⟨1, by decide⟩ : Fin 2)
    (join (join (⟨1, by decide⟩ : Fin 2) (⟨0, by decide⟩ : Fin 3)) (⟨1, by decide⟩ : Fin 2))).val ≠
    (join (⟨1, by decide⟩ : Fin 2)
    (join (join (⟨0, by decide⟩ : Fin 3) (⟨1, by decide⟩ : Fin 2)) (⟨1, by decide⟩ : Fin 2))).val := by decide
