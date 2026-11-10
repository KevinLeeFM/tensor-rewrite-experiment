import TensorRewrite.Pilot.Tensor

namespace TensorRewrite.Pilot.Bitwise

open Tensor

variable {rank : Nat} {shape : Shape rank} {width : Nat} (x : Tensor shape (BitVec width))

theorem not_not : map (fun a => ~~~a) (map (fun a => ~~~a) x) = x := by
  funext i
  simp only [map, BitVec.not_not]

theorem and_rhs_zero : map₂ (fun a b => a &&& b) x (constant (0#width)) = constant (0#width) := by
  funext i
  simp only [map₂, constant, BitVec.and_zero]

theorem and_lhs_zero : map₂ (fun a b => a &&& b) (constant (0#width)) x = constant (0#width) := by
  funext i
  simp only [map₂, constant, BitVec.zero_and]

theorem or_rhs_zero : map₂ (fun a b => a ||| b) x (constant (0#width)) = x := by
  funext i
  simp only [map₂, constant, BitVec.or_zero]

theorem or_lhs_zero : map₂ (fun a b => a ||| b) (constant (0#width)) x = x := by
  funext i
  simp only [map₂, constant, BitVec.zero_or]

theorem xor_rhs_zero : map₂ (fun a b => a ^^^ b) x (constant (0#width)) = x := by
  funext i
  simp only [map₂, constant, BitVec.xor_zero]

theorem xor_lhs_zero : map₂ (fun a b => a ^^^ b) (constant (0#width)) x = x := by
  funext i
  simp only [map₂, constant, BitVec.zero_xor]

theorem xor_self : map₂ (fun a b => a ^^^ b) x x = constant (0#width) := by
  funext i
  simp only [map₂, constant, BitVec.xor_self]

end TensorRewrite.Pilot.Bitwise
