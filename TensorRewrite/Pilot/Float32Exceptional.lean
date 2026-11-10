import TensorRewrite.Pilot.Tensor

namespace TensorRewrite.Pilot.Float32Exceptional

/-- Binary32 interchange bits; arithmetic is specified relationally below. -/
abbrev Bits := BitVec 32

/-- Only distinctions needed for the exceptional-multiplication contract. -/
inductive Class where
  | zero
  | finiteNonzero
  | infinity
  | nan
deriving DecidableEq, Repr

/-- Classify binary32 exponent/fraction fields, ignoring sign and NaN payload. -/
def classify (bits : Bits) : Class :=
  let exponent := (bits.toNat / 2 ^ 23) % 2 ^ 8
  let fraction := bits.toNat % 2 ^ 23
  if exponent = 255 then
    if fraction = 0 then .infinity else .nan
  else if exponent = 0 ∧ fraction = 0 then .zero else .finiteNonzero

/-- A necessary IEEE multiplication condition, deliberately leaving finite
rounding unconstrained. This overapproximation can refute incompatible outputs;
it cannot certify arbitrary finite arithmetic. -/
def MulCompatible (lhs rhs output : Bits) : Prop :=
  (classify lhs = .nan ∨ classify rhs = .nan ∨
    (classify lhs = .zero ∧ classify rhs = .infinity) ∨
    (classify lhs = .infinity ∧ classify rhs = .zero)) → classify output = .nan

/-- Exact binary32 values produced by conversion from a predicate. -/
def convertPredicate (p : Bool) : Bits := if p then 0x3f800000#32 else 0#32

/-- Value expression constructed by the inspected source replacement. -/
def rewritten (p : Bool) (operand : Bits) : Bits := if p then operand else 0#32

/-- Necessary condition for a pointwise tensor multiply to produce output. -/
def TensorMulCompatible {rank : Nat} {shape : Shape rank}
    (lhs rhs output : Tensor shape Bits) : Prop :=
  ∀ index, MulCompatible (lhs index) (rhs index) (output index)

end TensorRewrite.Pilot.Float32Exceptional
