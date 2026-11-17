module
public import Spec

@[expose] public section
set_option autoImplicit false
open TensorRewrite.Pilot TensorRewrite.Pilot.DynamicIndex
namespace Heldout.DynamicTranspose

theorem proof : Goal := by
  intro rank s p sizes starts fits α input
  funext outputIndex
  simp only [slice, Tensor.transpose, Tensor.reindex]
  congr 1
  funext axis
  apply Fin.ext
  simp [Fin.cast, Tensor.transposeIndex, dynamicSliceIndex, sourceStarts, transposedShape,
    p.output_input, TensorRewrite.Pilot.DynamicIndex.clampStart]

end Heldout.DynamicTranspose
