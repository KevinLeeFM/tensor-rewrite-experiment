module

public import TensorRewrite.Theory.ArithmeticFamily
public import TensorRewrite.Libraries.FloatingPoint
public import FloatLib.Floats.Formats.BinaryInterchange.Configured.Value.Core

/-! Exact arithmetic trees can fail IEEE binary32 laws under stored-bit observations. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ArithmeticFamily

open Pilot FloatLib.Floats

/-- Actual FloatLib binary32 arithmetic with explicit stored-sign negation; flags are unobserved. -/
def binary32Ops : Operations Binary32 where
  zero := ExecFloat.Binary.ofNatBits 0
  one := ExecFloat.Binary.ofNatBits 0x3f800000
  add := ExecFloat.add
  sub := ExecFloat.sub
  mul := ExecFloat.mul
  neg := fun value => ExecFloat.Binary.ofNatBits (ExecFloat.Binary.toNatBits value ^^^ 0x80000000)

/-- Evaluate an actual family expression at one scalar tensor coordinate using binary32 bits. -/
def binary32Bits (expression : Expr) (values : Nat → Nat) : Nat :=
  ExecFloat.Binary.toNatBits (expression.eval (shape := (Fin.elim0 : Shape 0)) binary32Ops
    (fun number => Tensor.constant (ExecFloat.Binary.ofNatBits (values number)))
    (fun _ => Tensor.constant false) (fun axis : Fin 0 => Fin.elim0 axis))

/-- Finite binary32 values refute the typed add-association profile: stored zero versus one. -/
theorem binary32_add_assoc_refuted :
    let values := fun number => if number = 0 then 0x4b800000 else
      if number = 1 then 0x3f800000 else 0xcb800000
    binary32Bits (Rule.addAssoc false false).lhs values = 0 ∧
      binary32Bits (Rule.addAssoc false false).rhs values = 0x3f800000 := by
  decide

/-- Gradual underflow refutes the typed product-association profile on finite inputs. -/
theorem binary32_mul_assoc_refuted :
    let values := fun number => if number = 0 then 1 else
      if number = 1 then 0x3f000000 else 0x40000000
    binary32Bits (Rule.mulAssoc false false).lhs values = 0 ∧
      binary32Bits (Rule.mulAssoc false false).rhs values = 1 := by
  decide

/-- Positive infinity times zero does not equal the exact-ring zero replacement. -/
theorem binary32_mul_zero_refuted :
    binary32Bits Rule.mulZeroRight.lhs (fun _ => 0x7f800000) ≠
      binary32Bits Rule.mulZeroRight.rhs (fun _ => 0x7f800000) := by
  decide

end TensorRewrite.Theory.ArithmeticFamily
