import TensorRewrite

open TensorRewrite.Pilot Tensor

-- Deliberately invalid: a single reversal is not identity on extent two.
example : reverse (fun _ => true)
    (fun i => (i 0).val : Tensor (fun (_ : Fin 1) => 2) Nat) =
    (fun i => (i 0).val) := by
  rfl
