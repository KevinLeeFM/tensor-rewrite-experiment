module

public import TensorRewrite.Pilot.Reshape
public import TensorRewrite.Pilot.LinearIndexLemmas
public import TensorRewrite.Pilot.ConstantGuardLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.Reshape

open LinearIndex

/-- Every tensor on a zero-element shape has the same logical values. -/
theorem tensor_eq_of_empty {rank : Nat} {shape : Shape rank} {α : Type}
    (empty : elementCount shape = 0) (lhs rhs : Tensor shape α) : lhs = rhs := by
  funext index
  have bound := (linearize shape index).isLt
  omega

/-- Reshape coordinate maps compose through any equal-count intermediate shape. -/
theorem reshapeIndex_compose {inputRank middleRank outputRank : Nat}
    (inputShape : Shape inputRank) (middleShape : Shape middleRank) (outputShape : Shape outputRank)
    (innerCount : elementCount inputShape = elementCount middleShape)
    (outerCount : elementCount middleShape = elementCount outputShape)
    (index : Index outputShape) :
    reshapeIndex inputShape middleShape innerCount
        (reshapeIndex middleShape outputShape outerCount index) =
      reshapeIndex inputShape outputShape (innerCount.trans outerCount) index := by
  have inverse := linearize_delinearize middleShape
    ⟨(linearize outputShape index).val, by
      rw [outerCount]
      exact (linearize outputShape index).isLt⟩
  have values := congrArg (fun position : Fin (elementCount middleShape) => position.val) inverse
  unfold reshapeIndex
  apply congrArg (delinearize inputShape)
  apply Fin.ext
  exact values

/-- Constant recognition remains sound with the actual rank-changing reshape map. -/
theorem reshapeView_constant {inputRank outputRank : Nat} {inputShape : Shape inputRank}
    (operand : ConstantGuard.View inputRank inputShape) (outputShape : Shape outputRank)
    (sameCount : elementCount inputShape = elementCount outputShape) (value : Bool)
    (guard : operand.isAll value = true) :
    (reshapeView operand outputShape sameCount).eval = Tensor.constant value :=
  (reshapeView operand outputShape sameCount).isAll_sound value guard

end TensorRewrite.Pilot.Reshape
