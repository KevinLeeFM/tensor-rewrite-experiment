module

public import TensorRewrite.Pilot.DynamicIndexValue

/-! Certificates comparing logical unsigned clamping with the observed evaluator
conversion model. These are not counterexamples to an algebraic-simplifier rule
and do not prove the C++ conversion or a production backend semantics. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.DynamicIndex

/-- The u64 high bit selects the upper edge logically and the lower edge after s64 conversion. -/
theorem unsigned64_high_bit_disagrees :
    clampStart 5 2 (unsignedValue (BitVec.ofNat 64 (2 ^ 63))) = 3 ∧
      clampStart 5 2 (evaluatorUnsigned64 (BitVec.ofNat 64 (2 ^ 63))) = 0 ∧
      clampStart 5 2 (unsignedValue (BitVec.ofNat 64 (2 ^ 63))) ≠
        clampStart 5 2 (evaluatorUnsigned64 (BitVec.ofNat 64 (2 ^ 63))) := by
  decide

/-- The largest u64 has the same clamping-profile disagreement. -/
theorem unsigned64_max_disagrees :
    clampStart 5 2 (unsignedValue (BitVec.ofNat 64 (2 ^ 64 - 1))) = 3 ∧
      clampStart 5 2 (evaluatorUnsigned64 (BitVec.ofNat 64 (2 ^ 64 - 1))) = 0 ∧
      clampStart 5 2 (unsignedValue (BitVec.ofNat 64 (2 ^ 64 - 1))) ≠
        clampStart 5 2 (evaluatorUnsigned64 (BitVec.ofNat 64 (2 ^ 64 - 1))) := by
  decide

/-- The two interpretations cannot be used as interchangeable u64 index semantics. -/
theorem unsigned64_not_universally_equal :
    ¬ (∀ bits : BitVec 64, clampStart 5 2 (unsignedValue bits) =
      clampStart 5 2 (evaluatorUnsigned64 bits)) := by
  intro agrees
  exact unsigned64_high_bit_disagrees.2.2 (agrees (BitVec.ofNat 64 (2 ^ 63)))

end TensorRewrite.Pilot.DynamicIndex
