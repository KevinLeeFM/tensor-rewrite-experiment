import AuxProof
set_option autoImplicit false
namespace ArtifactAux.DynamicSlice
#check (refuted : ¬ Goal)
example : (original 2 0 1 (by decide)).length = (replacement 1).length := by decide
example : (original 2 0 1 (by decide))[0]? = some (0 : Int) ∧
          (replacement 1)[0]? = some (1 : Int) := by decide
example : original 2 0 1 (by decide) = replacement 0 := by decide
example : original 2 1 1 (by decide) = replacement 1 := by decide
example : original 4 1 2 (by decide) = [1,2] := by decide
example : ¬ (2+1 ≤ 2) := by decide
end ArtifactAux.DynamicSlice
