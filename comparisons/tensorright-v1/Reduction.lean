module

public import TensorRewrite.Theory.ReductionAlgebra
public import TensorRewrite.Pilot.Permutation

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

/-- Unit reduced axes have the same total input and output element count. -/
theorem singleton_count (plan : Plan) (units : plan.UnitReducedAxes) :
    LinearIndex.elementCount plan.inputShape = LinearIndex.elementCount plan.outputShape :=
  elementCount_eq_of_units plan units

/-- `reduce/rule07`: summing unit axes is the same as removing those axes by reshape. -/
theorem singleton_reshape {α : Type} [AddZeroClass α] (plan : Plan)
    (units : plan.UnitReducedAxes) (input : Tensor plan.inputShape α) :
    reduceTensor plan (· + ·) 0 input =
      Reshape.reshapeTensor input plan.outputShape (singleton_count plan units) :=
  reduceTensor_sameCount plan (· + ·) 0 (fun value => zero_add value) input
    (singleton_count plan units)

/-- `reduce/rule08`: changing an axis label before the same reduction leaves values unchanged. -/
theorem relabel_singleton_reshape {α : Type} [AddZeroClass α] (plan : Plan)
    (units : plan.UnitReducedAxes) (input : Tensor plan.inputShape α) :
    reduceTensor plan (· + ·) 0
        (Tensor.transpose (AxisPermutation.identity plan.inputRank) (fun _ => rfl) input) =
      Reshape.reshapeTensor input plan.outputShape (singleton_count plan units) :=
  singleton_reshape plan units input

#print axioms singleton_count
#print axioms singleton_reshape
#print axioms relabel_singleton_reshape
#print axioms scalar_factor

end TensorRewrite.PaperComparison.Reduction
