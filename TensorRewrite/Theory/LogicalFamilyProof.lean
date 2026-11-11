module

public import TensorRewrite.Theory.LogicalFamily

/-! Soundness and finite-family coverage certificates for logical value rewrites. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.LogicalFamily

open Pilot

/-- Every rule in the family preserves all tensor values under its explicit side condition. -/
theorem rewrite_sound {domain : Domain} {rank : Nat} {shape : Shape rank}
    (rule : Rule domain) (inputs : Nat → Tensor shape domain.Value)
    (condition : rule.Condition inputs) : rule.lhs.eval inputs = rule.rhs.eval inputs := by
  cases domain with
  | predicate =>
    cases rule <;> funext index <;>
      simp_all [Rule.Condition, Rule.lhs, Rule.rhs, Expr.eval, Tensor.map, Tensor.map₂,
        Tensor.constant, Domain.not, Domain.and, Domain.or, Domain.xor, Domain.zero]
  | word width =>
    cases rule <;> funext index <;>
      simp_all [Rule.Condition, Rule.lhs, Rule.rhs, Expr.eval, Tensor.map, Tensor.map₂,
        Tensor.constant, Domain.not, Domain.and, Domain.or, Domain.xor, Domain.zero]

/-- The published family list contains every constructor; no admitted rule is skipped. -/
theorem allRules_complete {domain : Domain} (rule : Rule domain) : rule ∈ allRules domain := by
  cases domain <;> cases rule <;> simp [allRules]

/-- Enumeration contains no duplicate rule constructors. -/
theorem allRules_nodup (domain : Domain) : (allRules domain).Nodup := by
  cases domain <;> simp [allRules]

/-- Word-family reporting keys are uniform over all widths, including zero. -/
theorem word_keys_uniform (width : Nat) :
    (allRules (.word width)).map Rule.key = (allRules (.word 0)).map Rule.key := rfl

/-- Predicate values have twelve family obligations. -/
theorem predicate_count : (allRules .predicate).length = 12 := rfl

/-- Each arbitrary-width word family has eight obligations. -/
theorem word_count (width : Nat) : (allRules (.word width)).length = 8 := rfl

end TensorRewrite.Theory.LogicalFamily
