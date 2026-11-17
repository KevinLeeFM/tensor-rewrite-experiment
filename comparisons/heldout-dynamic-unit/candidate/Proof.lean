module
public import Spec

set_option autoImplicit false

@[expose] public section

namespace Heldout.DynamicUnit
open TensorRewrite.Pilot TensorRewrite.Pilot.DynamicIndex

theorem proof : Goal := by
  intro n m s t p sizes starts c α input
  funext out
  change input (project p (dynamicSliceIndex starts c.fits out)) =
    input (dynamicSliceIndex (sourceStarts p starts)
      (sourceSizes_fit p sizes c) (project (outputInsertion p sizes c) out))
  congr 1
  funext axis
  apply Fin.ext
  simp only [project, dynamicSliceIndex]
  let j := p.kept axis
  have he : t j = s axis := p.extent axis
  have hcoord :
      (Fin.cast ((outputInsertion p sizes c).extent axis)
        (out ((outputInsertion p sizes c).kept axis))).val = (out (p.kept axis)).val := by
    exact Fin.val_cast _ _
  rw [hcoord]
  by_cases hu : s axis = 1
  · have hs : sizes j = 1 := c.unitWidth j (by simpa [he] using hu)
    simp [j, he, hu, hs, sourceStarts, sourceSizes, clampStart]
    omega
  · simp [j, he, hu, sourceStarts, sourceSizes]

end Heldout.DynamicUnit

#print axioms Heldout.DynamicUnit.proof
