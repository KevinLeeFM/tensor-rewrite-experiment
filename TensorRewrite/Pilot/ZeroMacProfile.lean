module

public import TensorRewrite.Pilot.Tensor

/-! A necessary bit-observation profile for one zero-initialized binary32 MAC.
Only the signed-zero/unit pairs used in the diagnostic are constrained. This
is not a complete IEEE arithmetic or an adopted backend-permission model. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.ZeroMacProfile

/-- Binary32 interchange bits, without a complete arithmetic implementation. -/
abbrev Bits := BitVec 32

/-- Exact positive-zero interchange bits. -/
def positiveZero : Bits := 0#32

/-- Exact negative-zero interchange bits. -/
def negativeZero : Bits := 0x80000000#32

/-- Exact positive-one interchange bits. -/
def one : Bits := 0x3f800000#32

/-- Necessary signed-zero product condition for the observed (-0)*1 pair. -/
def IsMulCompatible (lhs rhs output : Bits) : Prop :=
  lhs = negativeZero ∧ rhs = one → output = negativeZero

/-- Necessary round-to-nearest mixed-zero addition condition for the diagnostic. -/
def IsAddCompatible (lhs rhs output : Bits) : Prop :=
  lhs = positiveZero ∧ rhs = negativeZero → output = positiveZero

/-- One product accumulated into positive zero before producing a Dot output. -/
def IsOneMacCompatible (output : Bits) : Prop :=
  ∃ product, IsMulCompatible negativeZero one product ∧ IsAddCompatible positiveZero product output

end TensorRewrite.Pilot.ZeroMacProfile
