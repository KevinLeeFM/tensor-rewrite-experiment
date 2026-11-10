import TensorRewrite

open TensorRewrite.Pilot.ScaledNestedSlice

example : original 1 (by decide) 7 1 2 witnessIndex =
    rewritten 1 (by decide) 1 2 witnessIndex := by
  rfl
