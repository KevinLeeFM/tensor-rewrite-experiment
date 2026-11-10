import TensorRewrite

-- A word equality does not justify decoding modular Add as unbounded Nat addition.
example : ((BitVec.ofNat 8 255) + (BitVec.ofNat 8 1)).toNat = 256 := by
  rfl
