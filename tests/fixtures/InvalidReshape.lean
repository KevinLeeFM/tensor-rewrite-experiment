import TensorRewrite

open TensorRewrite.Pilot.FiniteProduct

example : (join (1 : Fin 2) (0 : Fin 3)).val = 1 := by rfl
