module

public import TensorRewrite.Theory.ReductionAlgebra

/-! Paper-era reductions over exact integers and reals. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Reduction

open Pilot Pilot.Reduction Theory.ReductionAlgebra

/-- `reduce/rule03`: multiplication by the same scalar commutes with an additive reduction. -/
theorem scalar_factor {α : Type} [Semiring α] (plan : Plan) (scalar : α)
    (input : Tensor plan.inputShape α) :
    Tensor.map (scalar * ·) (reduceTensor plan (· + ·) 0 input) =
      reduceTensor plan (· + ·) 0 (Tensor.map (scalar * ·) input) := by
  have result := map_reduction plan (scalar * ·) (· + ·) (· + ·)
    (fun a b => (mul_add scalar a b).symm) 0 input
  simpa only [mul_zero] using result.symm

#print axioms scalar_factor

end TensorRewrite.PaperComparison.Reduction
