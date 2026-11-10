module

public import TensorRewrite.Pilot.Tensor

public section

namespace TensorRewrite.Pilot.Boolean

open Tensor

variable {rank : Nat} {shape : Shape rank} (x : Tensor shape (Bool))

theorem not_not : map Bool.not (map Bool.not x) = x := by
  funext i
  simp only [map, Bool.not_not]

theorem and_rhs_false : map₂ Bool.and x (constant false) = constant false := by
  funext i
  simp only [map₂, constant, Bool.and_false]

theorem and_rhs_true : map₂ Bool.and x (constant true) = x := by
  funext i
  simp only [map₂, constant, Bool.and_true]

theorem and_lhs_false : map₂ Bool.and (constant false) x = constant false := by
  funext i
  simp only [map₂, constant, Bool.false_and]

theorem and_lhs_true : map₂ Bool.and (constant true) x = x := by
  funext i
  simp only [map₂, constant, Bool.true_and]

theorem or_rhs_false : map₂ Bool.or x (constant false) = x := by
  funext i
  simp only [map₂, constant, Bool.or_false]

theorem or_rhs_true : map₂ Bool.or x (constant true) = constant true := by
  funext i
  simp only [map₂, constant, Bool.or_true]

theorem or_lhs_false : map₂ Bool.or (constant false) x = x := by
  funext i
  simp only [map₂, constant, Bool.false_or]

theorem or_lhs_true : map₂ Bool.or (constant true) x = constant true := by
  funext i
  simp only [map₂, constant, Bool.true_or]

theorem xor_self : map₂ Bool.xor x x = constant false := by
  funext i
  simp only [map₂, constant, Bool.xor_self]

theorem xor_rhs_zero : map₂ Bool.xor x (constant false) = x := by
  funext i
  simp only [map₂, constant, Bool.xor_false]

theorem xor_lhs_zero : map₂ Bool.xor (constant false) x = x := by
  funext i
  simp only [map₂, constant, Bool.false_xor]

end TensorRewrite.Pilot.Boolean
