import TensorRewrite

open TensorRewrite.Pilot.Float32Exceptional

example : classify (0#32) = .zero := by decide
example : classify (0x80000000#32) = .zero := by decide
example : classify (0x3f800000#32) = .finiteNonzero := by decide
example : classify (1#32) = .finiteNonzero := by decide
example : classify (0x7f800000#32) = .infinity := by decide
example : classify (0xff800000#32) = .infinity := by decide
example : classify (0x7fc00000#32) = .nan := by decide
example : classify (0x7f800001#32) = .nan := by decide

-- This necessary relation deliberately cannot certify finite arithmetic.
example : MulCompatible (0x3f800000#32) (0x3f800000#32) (0#32) := by
  unfold MulCompatible
  decide
