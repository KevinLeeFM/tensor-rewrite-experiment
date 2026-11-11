import TensorRewrite.Theory.ConcatenationGraphCounterexamples

open TensorRewrite.Pilot TensorRewrite.Theory TensorRewrite.Theory.Concatenation
open TensorRewrite.Theory.ConcatenationFamily

example :
    concatenate [diagnosticCrop.blockWith coordinateData ⟨0, 1, 1⟩ 1 (by decide),
        diagnosticCrop.blockWith coordinateData ⟨2, 3, 1⟩ 1 (by decide)]
        (lineIndex (1 : Fin 2)) =
      (diagnosticCrop.blockWith coordinateData ⟨0, 3, 1⟩ 3 (by decide)).values
        (lineIndex (1 : Fin 3)) := by decide


example :
    concatenate [constantBlock 1 7, (⟨1, Tensor.constant 9⟩ : Block lineFrame Nat)]
        (lineIndex (0 : Fin 2)) =
      ShapeTransport.tensorAlong (edgePadding_shape (extent := 1) lineFrame 0 1)
        ((lineFrame.edgePadding 0 1).tensor 7 (Tensor.constant 9))
        (lineIndex (0 : Fin 2)) := by decide


example :
    concatenate [constantBlock 1 7, (⟨1, Tensor.constant 9⟩ : Block lineFrame Nat)]
        (lineIndex (0 : Fin 2)) =
      ShapeTransport.tensorAlong (edgePadding_shape (extent := 1) lineFrame 1 0)
        ((lineFrame.edgePadding 1 0).tensor 8 (Tensor.constant 9))
        (lineIndex (0 : Fin 2)) := by decide


example :
    LinearIndex.elementCount (lineFrame.shape 2) =
      LinearIndex.elementCount (Fin.elim0 : Shape 0) := by decide
