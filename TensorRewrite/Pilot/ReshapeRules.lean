module

public import TensorRewrite.Pilot.ReshapeLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.Reshape

open LinearIndex

/-- Reshaping to the same logical shape preserves every value. -/
theorem reshapeTensor_identity {rank : Nat} {shape : Shape rank} {α : Type}
    (input : Tensor shape α) : reshapeTensor input shape rfl = input := by
  funext index
  exact congrArg input (delinearize_linearize shape index)

/-- Two logical reshapes equal a direct reshape, with arbitrary intermediate rank. -/
theorem reshapeTensor_compose {inputRank middleRank outputRank : Nat}
    {inputShape : Shape inputRank} {α : Type} (input : Tensor inputShape α)
    (middleShape : Shape middleRank) (outputShape : Shape outputRank)
    (innerCount : elementCount inputShape = elementCount middleShape)
    (outerCount : elementCount middleShape = elementCount outputShape) :
    reshapeTensor (reshapeTensor input middleShape innerCount) outputShape outerCount =
      reshapeTensor input outputShape (innerCount.trans outerCount) := by
  funext index
  exact congrArg input (reshapeIndex_compose inputShape middleShape outputShape
    innerCount outerCount index)

/-- A zero-element reshape has the same logical values as any well-typed replacement. -/
theorem reshapeTensor_empty {inputRank outputRank : Nat} {inputShape : Shape inputRank}
    {α : Type} (input : Tensor inputShape α) (outputShape : Shape outputRank)
    (sameCount : elementCount inputShape = elementCount outputShape)
    (empty : elementCount outputShape = 0) (replacement : Tensor outputShape α) :
    reshapeTensor input outputShape sameCount = replacement :=
  tensor_eq_of_empty empty _ _

end TensorRewrite.Pilot.Reshape
