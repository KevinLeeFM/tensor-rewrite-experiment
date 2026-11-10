module

public import TensorRewrite.Pilot.Tensor

/-! Necessary NaN behavior of ordinary ordered comparisons (LT/LE/GT/GE).
This deliberately partial profile does not specify finite arithmetic, operand
producers or backend permissions. It is independent of IsNonNegative. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.OrderedCompareProfile

/-- Binary32 interchange representation. -/
abbrev Bits := BitVec 32

/-- A binary32 NaN has an all-one exponent and a nonzero fraction. -/
def IsNaN (bits : Bits) : Prop :=
  (bits.toNat / 2 ^ 23) % 2 ^ 8 = 255 ∧ bits.toNat % 2 ^ 23 ≠ 0

instance (bits : Bits) : Decidable (IsNaN bits) :=
  inferInstanceAs (Decidable
    ((bits.toNat / 2 ^ 23) % 2 ^ 8 = 255 ∧ bits.toNat % 2 ^ 23 ≠ 0))

/-- An ordered comparison with either NaN operand must return false. -/
def IsOrderedCompatible (lhs rhs : Bits) (output : Bool) : Prop :=
  (IsNaN lhs ∨ IsNaN rhs) → output = false

instance (lhs rhs : Bits) (output : Bool) : Decidable (IsOrderedCompatible lhs rhs output) :=
  inferInstanceAs (Decidable ((IsNaN lhs ∨ IsNaN rhs) → output = false))

/-- A quiet NaN used to link the profile to the native diagnostic. -/
def quietNaN : Bits := 0x7fc00000#32

/-- Exact positive zero used by the source's comparison patterns. -/
def zero : Bits := 0#32

end TensorRewrite.Pilot.OrderedCompareProfile
