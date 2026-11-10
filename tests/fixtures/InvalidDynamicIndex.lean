import TensorRewrite

open TensorRewrite.Pilot.DynamicIndex

-- An unsigned high-bit start cannot silently use the signed conversion model.
example : clampStart 5 2 (unsignedValue (BitVec.ofNat 64 (2 ^ 63))) =
    clampStart 5 2 (evaluatorUnsigned64 (BitVec.ofNat 64 (2 ^ 63))) := by
  rfl
