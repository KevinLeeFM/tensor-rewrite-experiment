module

public import TensorRewrite.Pilot.ZeroMacProfile

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.ZeroMacProfile

/-- The minimal profile permits the observed original positive-zero result. -/
theorem positive_zero_consistent : IsOneMacCompatible positiveZero :=
  ⟨negativeZero, fun _ => rfl, fun _ => rfl⟩

/-- Every outcome admitted by this one-MAC profile is positive zero. -/
theorem one_mac_positive (output : Bits) (valid : IsOneMacCompatible output) :
    output = positiveZero := by
  obtain ⟨product, multiply, add⟩ := valid
  have value := multiply ⟨rfl, rfl⟩
  exact add ⟨rfl, value⟩

/-- Omitting accumulation yields a negative zero incompatible with this strict profile. -/
theorem negative_zero_incompatible : ¬ IsOneMacCompatible negativeZero := by
  intro valid
  have impossible := one_mac_positive negativeZero valid
  exact (by decide : negativeZero ≠ positiveZero) impossible

/-- The permitted original value and replacement product differ in their bits. -/
theorem zero_bits_differ : positiveZero ≠ negativeZero := by decide

end TensorRewrite.Pilot.ZeroMacProfile
