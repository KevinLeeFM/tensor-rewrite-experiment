import TensorRewrite

-- Wrong-sign mutation of x - (x + y) => -y at a concrete nonempty value.
example : (3#8) - ((3#8) + (1#8)) = (1#8) := by
  rfl
