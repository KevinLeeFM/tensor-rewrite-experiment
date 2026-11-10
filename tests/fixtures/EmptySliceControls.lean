import TensorRewrite

open TensorRewrite.Pilot.SliceShape

-- C++ signed division truncates toward zero; Lean's ordinary Int `/` does not.
example : (-1 : Int).tdiv 2 = 0 := by decide
example : (-1 : Int) / 2 = -1 := by decide

-- These are malformed declarations, not legal empty slices.
example : ¬ IsWellFormed 4 0 { start := 2, limit := 1, stride := 2 } := by decide
example : ¬ IsWellFormed 4 0 { start := 1, limit := 1, stride := 0 } := by decide

-- Boundaries and a nonempty control prevent a reject-everything contract.
example : IsWellFormed 4 0 { start := 4, limit := 4, stride := 1 } := by decide
example : IsWellFormed 4 1 { start := 1, limit := 3, stride := 3 } := by decide
example : IsWellFormed 4 1
    (removeRedundantStride { start := 1, limit := 3, stride := 3 }) := by decide
example : IsWellFormed 4 1
    (reorderReverse 4 { start := 1, limit := 3, stride := 3 }) := by decide
