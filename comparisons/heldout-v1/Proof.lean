module

public import Spec

public section
set_option autoImplicit false
namespace TensorRewrite.Heldout.MixedRadix3
/-- Frozen narrow mathematical rewrite, proved without changing its semantics. -/
theorem mixedRadix3 : Goal := by
  intro a b c _ i j k
  simp [original, sourceIota, replacement, Pilot.FiniteProduct.join,
    Nat.mul_comm, Nat.mul_left_comm, Nat.add_comm,
    Nat.add_left_comm]
end TensorRewrite.Heldout.MixedRadix3
#print axioms TensorRewrite.Heldout.MixedRadix3.mixedRadix3
