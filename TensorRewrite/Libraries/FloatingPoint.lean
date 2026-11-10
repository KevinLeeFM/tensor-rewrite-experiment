module

public import FloatLib.Floats.Formats.BinaryInterchange.Configured.Plan.Instances
public import FloatLib.Floats.Formats.BinaryInterchange.Configured.Type
public import FloatLib.Floats.ExecFloat.Proof.Arithmetic
public import TensorRewrite.Pilot.Tensor

/-! Scalar reference refinements lifted to arbitrary-rank logical tensors.
These equations compare stored values; exception flags and XLA correspondence are separate. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Libraries

open FloatLib.Floats

/-- Certified binary32 addition agrees with FloatLib's reference operation. -/
theorem binary32_add_eq_spec (x y : Binary32) :
    ExecFloat.add x y = ExecFloat.Spec.add x y :=
  ExecFloat.Proof.add_eq_spec x y

/-- Certified binary32 multiplication agrees with FloatLib's reference operation. -/
theorem binary32_mul_eq_spec (x y : Binary32) :
    ExecFloat.mul x y = ExecFloat.Spec.mul x y :=
  ExecFloat.Proof.mul_eq_spec x y

/-- The scalar addition refinement holds at every bounded tensor coordinate. -/
theorem tensor_binary32_add_eq_spec {rank : Nat} {shape : Pilot.Shape rank}
    (x y : Pilot.Tensor shape Binary32) :
    Pilot.Tensor.map₂ ExecFloat.add x y = Pilot.Tensor.map₂ ExecFloat.Spec.add x y := by
  funext index
  exact binary32_add_eq_spec (x index) (y index)

end TensorRewrite.Libraries
