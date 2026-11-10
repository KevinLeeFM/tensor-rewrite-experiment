import TensorRewrite

open TensorRewrite.Pilot.SliceShape

-- Requiring a well-formed output would incorrectly exclude this legal input.
example : (removeRedundantStride emptyWitness).elementCount = 0 := by
  rfl
