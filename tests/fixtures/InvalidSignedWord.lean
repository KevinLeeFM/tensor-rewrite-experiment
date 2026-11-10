import TensorRewrite

set_option autoImplicit false

-- The minimum signed value wraps under Negate; its decoded result is not positive 128.
example : (-(BitVec.ofInt 8 (-128))).toInt = -(-128 : Int) := by
  rfl
