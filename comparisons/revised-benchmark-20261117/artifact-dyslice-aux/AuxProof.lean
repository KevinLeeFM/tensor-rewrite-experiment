import AuxSpec
set_option autoImplicit false
namespace ArtifactAux.DynamicSlice

theorem witness : original 2 0 1 (by decide) = [0] ∧ replacement 1 = [1] := by decide

theorem refuted : ¬ Goal := by
  intro h
  have e := h 2 0 1 (by decide) 1
  rw [witness.1,witness.2] at e
  exact (by decide : ([0] : List Int) ≠ [1]) e
#print axioms witness
#print axioms refuted
end ArtifactAux.DynamicSlice
