module

public import TensorRewrite.Theory.ConcatenationPadLemmas

/-! Paper-era Pad cases over arbitrary element values. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Pad

open Pilot Theory.Concatenation

/-- `pad/rule01`: zero edge and interior padding leaves every coordinate unchanged. -/
theorem identity {rank extent : Nat} {α : Type} (frame : Frame rank)
    (fill : α) (input : Tensor (frame.shape extent) α) :
    Theory.ShapeTransport.tensorAlong (edgePadding_shape frame 0 0)
        ((frame.edgePadding 0 0).tensor fill input) =
      Theory.ShapeTransport.tensorAlong (by simp) input := by
  funext index
  rw [edgePadding_value]
  have inside : 0 ≤ (frame.position index).val ∧ (frame.position index).val < 0 + extent := by
    constructor
    · omega
    · simpa using (frame.position index).isLt
  rw [dite_eq_left inside]
  unfold Theory.ShapeTransport.tensorAlong
  apply congrArg input
  funext axis
  apply Fin.ext
  by_cases same : axis = frame.axis
  · subst axis
    simp [Frame.withPosition, Frame.position, Theory.ShapeTransport.indexAlong]
  · simp [Frame.withPosition, Frame.position, Theory.ShapeTransport.indexAlong, same]

#print axioms identity

end TensorRewrite.PaperComparison.Pad
