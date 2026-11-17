module
public import Proof
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceComposeStatic
open TensorRewrite.Pilot.SliceShape

/-- A nonempty composition. -/
example : IsWellFormed 10 5 ⟨3, 8, 1⟩ ∧ IsWellFormed 5 2 ⟨1, 3, 1⟩ ∧
    IsWellFormed 10 2 ⟨3 + 1, 3 + 3, 1⟩ := by decide
/-- Empty interval at a nonzero location. -/
example : IsWellFormed 10 5 ⟨3, 8, 1⟩ ∧ IsWellFormed 5 0 ⟨2, 2, 1⟩ ∧
    IsWellFormed 10 0 ⟨3 + 2, 3 + 2, 1⟩ := by decide
/-- The outer limit can reach the inner endpoint. -/
example : IsWellFormed 10 5 ⟨3, 8, 1⟩ ∧ IsWellFormed 5 3 ⟨2, 5, 1⟩ ∧
    IsWellFormed 10 3 ⟨3 + 2, 3 + 5, 1⟩ := by decide
/-- Omitting the inner offset on the start produces an invalid declared extent. -/
example : IsWellFormed 10 5 ⟨3, 8, 1⟩ ∧ IsWellFormed 5 2 ⟨1, 3, 1⟩ ∧
    ¬ IsWellFormed 10 2 ⟨1, 3 + 3, 1⟩ := by decide
end RevisedBenchmark.SliceComposeStatic
