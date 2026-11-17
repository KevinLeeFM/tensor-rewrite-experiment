module
public import Proof
public section
set_option autoImplicit false
open TensorRewrite.Heldout.MixedRadix3
/-- Exact frozen goal, no proposition weakened by proof construction. -/
example : Goal := mixedRadix3
/-- Guard has a concrete nonempty instance. -/
example : admissible 2 3 4 := by unfold admissible; decide
/-- Nontrivial observation on the original tensor. -/
example : original (⟨1, by decide⟩ : Fin 2) (⟨2, by decide⟩ : Fin 3)
    (⟨3, by decide⟩ : Fin 4) = 23 := by decide
/-- Deliberately dropping the outer-axis term is detected. -/
example : original (⟨1, by decide⟩ : Fin 2) (⟨2, by decide⟩ : Fin 3)
    (⟨3, by decide⟩ : Fin 4) ≠ 3 + 4 * 2 := by decide
#print axioms TensorRewrite.Heldout.MixedRadix3.mixedRadix3
