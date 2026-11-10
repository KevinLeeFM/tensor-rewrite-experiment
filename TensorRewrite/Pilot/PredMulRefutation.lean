import TensorRewrite.Pilot.Float32Exceptional

namespace TensorRewrite.Pilot.Float32Exceptional

/-- Positive infinity witness; independent of rounding and NaN payload choice. -/
theorem false_inf_refutes :
    ¬ MulCompatible (convertPredicate false) (0x7f800000#32)
      (rewritten false (0x7f800000#32)) := by
  unfold MulCompatible
  decide

/-- Negative infinity is also an exceptional multiplication input. -/
theorem false_neg_inf_refutes :
    ¬ MulCompatible (convertPredicate false) (0xff800000#32)
      (rewritten false (0xff800000#32)) := by
  unfold MulCompatible
  decide

/-- Quiet NaN input cannot be replaced by an ordinary zero result. -/
theorem false_nan_refutes :
    ¬ MulCompatible (convertPredicate false) (0x7fc00000#32)
      (rewritten false (0x7fc00000#32)) := by
  unfold MulCompatible
  decide

/-- The other multiplication operand order fails the same necessary contract. -/
theorem inf_false_refutes :
    ¬ MulCompatible (0x7f800000#32) (convertPredicate false)
      (rewritten false (0x7f800000#32)) := by
  unfold MulCompatible
  decide

theorem neg_inf_false_refutes :
    ¬ MulCompatible (0xff800000#32) (convertPredicate false)
      (rewritten false (0xff800000#32)) := by
  unfold MulCompatible
  decide

theorem nan_false_refutes :
    ¬ MulCompatible (0x7fc00000#32) (convertPredicate false)
      (rewritten false (0x7fc00000#32)) := by
  unfold MulCompatible
  decide

/-- The partial relation is consistent: all NaN results satisfy this necessary
condition. This deliberately does not certify such behavior on finite inputs. -/
theorem canonical_nan_allowed (lhs rhs : Bits) : MulCompatible lhs rhs (0x7fc00000#32) := by
  intro _
  decide

theorem not_universally_valid :
    ¬ (∀ p operand, MulCompatible (convertPredicate p) operand (rewritten p operand)) := by
  intro universal
  exact false_inf_refutes (universal false (0x7f800000#32))

/-- Every infinity or NaN encoding is a witness, independently of its sign
and payload. The finite arithmetic branch is never used. -/
theorem false_nonfinite_refutes (operand : Bits)
    (nonfinite : classify operand = .infinity ∨ classify operand = .nan) :
    ¬ MulCompatible (convertPredicate false) operand (rewritten false operand) := by
  intro allowed
  have converted_zero : classify (convertPredicate false) = .zero := by decide
  have zero_not_nan : classify (0#32) ≠ .nan := by decide
  apply zero_not_nan
  apply allowed
  rcases nonfinite with infinite | nan
  · exact Or.inr (Or.inr (Or.inl ⟨converted_zero, infinite⟩))
  · exact Or.inr (Or.inl nan)

/-- Any implementation satisfying the necessary contract must differ from zero
on these inputs. No particular finite multiplication implementation is assumed. -/
theorem every_compliant_mul_differs
    (mul : Bits → Bits → Bits)
    (compliant : ∀ lhs rhs, MulCompatible lhs rhs (mul lhs rhs)) :
    mul (convertPredicate false) (0x7f800000#32) ≠ rewritten false (0x7f800000#32) := by
  intro equal
  have allowed := compliant (convertPredicate false) (0x7f800000#32)
  rw [equal] at allowed
  exact false_inf_refutes allowed

/-- Rank-zero tensors have an actual index, so this is a tensor counterexample
rather than a vacuous assertion over an empty domain. -/
theorem scalar_tensor_refutes :
    ¬ TensorMulCompatible
      (Tensor.constant (convertPredicate false) : Tensor (fun (_ : Fin 0) => 0) Bits)
      (Tensor.constant (0x7f800000#32))
      (Tensor.constant (rewritten false (0x7f800000#32))) := by
  intro allowed
  exact false_inf_refutes (allowed (fun axis => Fin.elim0 axis))

/-- Rejection by the necessary contract transfers to every stronger relational
semantics, including any complete IEEE model that refines this condition. -/
theorem any_refining_relation_rejects
    (semantics : Bits → Bits → Bits → Prop)
    (refinement : ∀ lhs rhs output, semantics lhs rhs output → MulCompatible lhs rhs output) :
    ¬ semantics (convertPredicate false) (0x7f800000#32)
      (rewritten false (0x7f800000#32)) := by
  intro allowed
  exact false_inf_refutes (refinement _ _ _ allowed)

end TensorRewrite.Pilot.Float32Exceptional
