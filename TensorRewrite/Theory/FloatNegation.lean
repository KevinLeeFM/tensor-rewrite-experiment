module

public import FloatLib.Floats.Formats.BinaryInterchange.Arithmetic.SignedSemantics.Core
public import TensorRewrite.Pilot.Indexing

/-! Bit-exact negation identities in FloatLib's format-parameterized value model.
No finiteness or non-NaN assumption is imposed. Exception flags are not observations here. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.FloatNegation

open FloatLib.Floats.Formats.BinaryInterchange

/-- Double negation preserves the entire modeled encoding for every supported format. -/
theorem scalar_involution {format : FloatFormat} (x : Model format) :
    Model.neg (Model.neg x) = x :=
  Model.neg_neg x

/-- Tensor double negation holds at arbitrary finite ranks and extents, including empty shapes. -/
theorem tensor_involution {rank : Nat} {shape : Pilot.Shape rank} {format : FloatFormat}
    (x : Pilot.Tensor shape (Model format)) :
    Pilot.Tensor.map Model.neg (Pilot.Tensor.map Model.neg x) = x := by
  funext index
  exact scalar_involution (x index)

/-- Negation commutes with any total coordinate map, including rank-changing maps. -/
theorem reindex_neg {inputRank outputRank : Nat}
    {inputShape : Pilot.Shape inputRank} {outputShape : Pilot.Shape outputRank}
    {format : FloatFormat} (indices : Pilot.Index outputShape → Pilot.Index inputShape)
    (x : Pilot.Tensor inputShape (Model format)) :
    Pilot.Tensor.reindex indices (Pilot.Tensor.map Model.neg x) =
      Pilot.Tensor.map Model.neg (Pilot.Tensor.reindex indices x) := rfl

/-- Selected-axis reversal can move across floating-point negation without numeric assumptions. -/
theorem reverse_neg {rank : Nat} {shape : Pilot.Shape rank} {format : FloatFormat}
    (axes : Fin rank → Bool) (x : Pilot.Tensor shape (Model format)) :
    Pilot.Tensor.reverse axes (Pilot.Tensor.map Model.neg x) =
      Pilot.Tensor.map Model.neg (Pilot.Tensor.reverse axes x) := rfl

end TensorRewrite.Theory.FloatNegation
