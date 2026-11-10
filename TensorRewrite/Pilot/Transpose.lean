import TensorRewrite.Pilot.Permutation

namespace TensorRewrite.Pilot.Transpose

open Tensor

variable {rank : Nat} {a b c : Shape rank} {α : Type}

/-- An identity axis permutation changes no values. -/
theorem transpose_identity (x : Tensor a α) :
    transpose (AxisPermutation.identity rank) (fun _ => rfl) x = x := rfl

/-- Transpose composition preserves the order of the two axis maps. -/
theorem transpose_comp (p q : AxisPermutation rank)
    (hp : ∀ axis, b (p.inputToOutput axis) = a axis)
    (hq : ∀ axis, c (q.inputToOutput axis) = b axis) (x : Tensor a α) :
    transpose q hq (transpose p hp x) =
      transpose (p.comp q) (fun axis => (hq (p.inputToOutput axis)).trans (hp axis)) x := by
  funext index
  apply congrArg x
  funext axis
  apply Fin.ext
  rfl

/-- A uniform tensor remains uniform under every legal transpose. -/
theorem transpose_constant (p : AxisPermutation rank)
    (extents : ∀ axis, b (p.inputToOutput axis) = a axis) (v : α) :
    transpose p extents (constant v) = constant v := rfl

end TensorRewrite.Pilot.Transpose
