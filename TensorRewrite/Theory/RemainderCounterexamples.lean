module

public import TensorRewrite.Theory.RemainderProof

/-! Concrete sign and overflow failures when remainder rewrite contracts are weakened. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Remainder

/-- Dropping signed correction changes truncating remainder minus one into positive three. -/
theorem signed_correction_refuted :
    ((11#4).srem 4#4).toInt = -1 ∧ (11#4 &&& (4#4 - 1#4)).toInt = 3 := by
  decide

/-- Unsigned Iota offset removal fails after actual modular addition wraps. -/
theorem unsigned_wrap_refuted :
    (((7#4) + 10#4) % 10#4).toNat = 1 ∧ (7#4 % 10#4).toNat = 7 := by
  decide

/-- A sum can fit unsigned width yet cross the sign bit, changing truncating remainder. -/
theorem signed_wrap_refuted :
    (5 : Nat) + 3 < 2 ^ 4 ∧
    ((5#4 + 3#4).srem 3#4).toInt = -2 ∧ ((5#4).srem 3#4).toInt = 2 := by
  decide

end TensorRewrite.Theory.Remainder
