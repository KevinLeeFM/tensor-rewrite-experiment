import TensorRewrite

open TensorRewrite.Pilot.Float32Exceptional

-- The observed replacement zero cannot satisfy the source's required NaN class.
example : MulCompatible (convertPredicate false) (0x7f800000#32)
    (rewritten false (0x7f800000#32)) := by
  intro _
  rfl
