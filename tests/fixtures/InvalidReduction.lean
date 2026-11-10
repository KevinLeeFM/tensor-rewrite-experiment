import TensorRewrite

example : ∀ initial value : Bool, Bool.and initial value = value := by
  intro initial value
  rfl
