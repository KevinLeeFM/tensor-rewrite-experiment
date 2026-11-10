import TensorRewrite.Pilot.Indexing

namespace TensorRewrite.Pilot.Tensor

variable {rank : Nat} {shape : Shape rank}

/-- Reversing the same selected coordinates twice restores the original index. -/
theorem reverseIndex_reverseIndex (axes : Fin rank → Bool) (i : Index shape) :
    reverseIndex axes (reverseIndex axes i) = i := by
  funext axis
  cases h : axes axis <;> simp [reverseIndex, h]

/-- Per-axis reversal composes according to exclusive-or of selection masks. -/
theorem reverseIndex_comp (a b : Fin rank → Bool) (i : Index shape) :
    reverseIndex a (reverseIndex b i) = reverseIndex (fun axis => a axis ^^ b axis) i := by
  funext axis
  cases ha : a axis <;> cases hb : b axis <;> simp [reverseIndex, ha, hb]

end TensorRewrite.Pilot.Tensor
