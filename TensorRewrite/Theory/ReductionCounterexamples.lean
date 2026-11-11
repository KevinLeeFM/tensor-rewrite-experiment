module

public import TensorRewrite.Theory.ReductionAlgebra

/-! Counterexample certificates for omitted nonemptiness and reducer algebra premises. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ReductionAlgebra

open Pilot Pilot.Reduction

/-- An empty maximum fiber returns the initializer, not the broadcast input value. -/
theorem empty_constant_refuted :
    reduceTensor (.reduce 0 .scalar) Nat.max 1 (Tensor.constant 9)
        (fun axis => Fin.elim0 axis) = 1 ∧ (1 : Nat) ≠ 9 := by decide

/-- Nonneutral initializers are repeated when separately initialized reductions are merged. -/
theorem repeated_initializer_refuted :
    (([[1], [2]] : List (List Nat)).map fun block => block.foldl (· + ·) 7).foldl (· + ·) 7 = 24 ∧
      ([1, 2] : List Nat).foldl (· + ·) 7 = 10 ∧ (24 : Nat) ≠ 10 := by decide

/-- A zero initializer alone does not justify regrouping a nonassociative operation. -/
theorem nonassociative_regrouping_refuted :
    (([[1, 2], [3, 4]] : List (List Nat)).map fun block =>
      block.foldl (fun a b => 2 * a + b) 0).foldl (fun a b => 2 * a + b) 0 = 18 ∧
      ([1, 2, 3, 4] : List Nat).foldl (fun a b => 2 * a + b) 0 = 26 ∧
      (18 : Nat) ≠ 26 := by decide

end TensorRewrite.Theory.ReductionAlgebra
