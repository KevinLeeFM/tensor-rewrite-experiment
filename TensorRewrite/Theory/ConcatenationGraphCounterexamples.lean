module

public import TensorRewrite.Theory.ConcatenationAdjacent
public import TensorRewrite.Theory.ConcatenationPad
public import TensorRewrite.Theory.ConcatenationRepeat
public import TensorRewrite.Theory.ConcatenationCounterexamples

/-! Missing-guard diagnostics for the additional pure concatenation graphs. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConcatenationFamily

open Pilot Concatenation

/-- A one-axis identity crop used to expose actual Slice source coordinates. -/
def diagnosticCrop : Crop lineFrame where
  outputExtents := fun _ => 1
  attributes := fun _ => ⟨0, 1, 1⟩
  validOther axis different := by
    have same : axis = lineFrame.axis := Subsingleton.elim _ _
    exact False.elim (different same)

/-- Read each source coordinate as data, independently of the Slice attributes. -/
def coordinateData : Tensor (lineFrame.shape 3) Nat := fun index => (index 0).val

/-- Gapped Slice operands disagree with a contiguous merged Slice at the second output point. -/
theorem gapped_slices_refuted :
    concatenate [diagnosticCrop.blockWith coordinateData ⟨0, 1, 1⟩ 1 (by decide),
        diagnosticCrop.blockWith coordinateData ⟨2, 3, 1⟩ 1 (by decide)]
        (lineIndex (1 : Fin 2)) ≠
      (diagnosticCrop.blockWith coordinateData ⟨0, 3, 1⟩ 3 (by decide)).values
        (lineIndex (1 : Fin 3)) := by decide

/-- Leading fill cannot be moved to the high edge while preserving values. -/
theorem padding_side_refuted :
    concatenate [constantBlock 1 7, (⟨1, Tensor.constant 9⟩ : Block lineFrame Nat)]
        (lineIndex (0 : Fin 2)) ≠
      ShapeTransport.tensorAlong (edgePadding_shape (extent := 1) lineFrame 0 1)
        ((lineFrame.edgePadding 0 1).tensor 7 (Tensor.constant 9))
        (lineIndex (0 : Fin 2)) := by decide

/-- Correct padding geometry does not permit changing the actual scalar fill. -/
theorem padding_fill_refuted :
    concatenate [constantBlock 1 7, (⟨1, Tensor.constant 9⟩ : Block lineFrame Nat)]
        (lineIndex (0 : Fin 2)) ≠
      ShapeTransport.tensorAlong (edgePadding_shape (extent := 1) lineFrame 1 0)
        ((lineFrame.edgePadding 1 0).tensor 8 (Tensor.constant 9))
        (lineIndex (0 : Fin 2)) := by decide

/-- Deleting a nonunit axis does not satisfy the ordinary Reshape count obligation. -/
theorem nonunit_delete_refuted :
    LinearIndex.elementCount (lineFrame.shape 2) ≠
      LinearIndex.elementCount (Fin.elim0 : Shape 0) := by decide

end TensorRewrite.Theory.ConcatenationFamily
