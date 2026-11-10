module

public import TensorRewrite.Pilot.LinearIndex
public import TensorRewrite.Pilot.ConstantGuard

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.Reshape

open LinearIndex

/-- Preserve logical linear position between shapes with equal element counts. -/
def reshapeIndex {inputRank outputRank : Nat} (inputShape : Shape inputRank)
    (outputShape : Shape outputRank)
    (sameCount : elementCount inputShape = elementCount outputShape)
    (index : Index outputShape) : Index inputShape :=
  delinearize inputShape ⟨(linearize outputShape index).val, by
    rw [sameCount]
    exact (linearize outputShape index).isLt⟩

/-- Logical reshape is independent of physical layout and preserves element order. -/
def reshapeTensor {inputRank outputRank : Nat} {inputShape : Shape inputRank} {α : Type}
    (input : Tensor inputShape α) (outputShape : Shape outputRank)
    (sameCount : elementCount inputShape = elementCount outputShape) : Tensor outputShape α :=
  fun index => input (reshapeIndex inputShape outputShape sameCount index)

/-- Recognized reshape view using the derived logical index map across ranks. -/
def reshapeView {inputRank outputRank : Nat} {inputShape : Shape inputRank}
    (operand : ConstantGuard.View inputRank inputShape) (outputShape : Shape outputRank)
    (sameCount : elementCount inputShape = elementCount outputShape) :
    ConstantGuard.View outputRank outputShape :=
  .reindex .reshape operand (reshapeIndex inputShape outputShape sameCount)

end TensorRewrite.Pilot.Reshape
