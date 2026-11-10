module

public import TensorRewrite.Pilot.Tensor

/-! Signed interpretation and narrowing of unsigned intermediate arithmetic.
The source evaluator uses wider intermediates for narrow stored integer types. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.PromotedWordArithmetic

/-- Narrowing an integer encoded in a wider word gives its direct narrow encoding. -/
theorem narrow_ofInt {width promoted : Nat} (bound : width ≤ promoted) (value : Int) :
    (BitVec.ofInt promoted value).setWidth width = BitVec.ofInt width value := by
  cases value with
  | ofNat value => simpa using BitVec.setWidth_ofNat_of_le bound value
  | negSucc value =>
    simp only [BitVec.ofInt_negSucc_eq_not_ofNat, BitVec.setWidth_not bound,
      BitVec.setWidth_ofNat_of_le bound]

/-- Widening a signed word preserves its integer value exactly. -/
theorem signed_promotion_exact {width promoted : Nat} (bound : width ≤ promoted)
    (value : BitVec width) : (BitVec.ofInt promoted value.toInt).toInt = value.toInt :=
  BitVec.toInt_signExtend_of_le bound

/-- Signed reinterpretation of an intermediate word does not change its narrowed bits. -/
theorem signed_cast_narrow {width promoted : Nat} (bound : width ≤ promoted)
    (value : BitVec promoted) :
    BitVec.ofInt width value.toInt = value.setWidth width :=
  BitVec.signExtend_eq_setWidth_of_le value bound

/-- Promote signed inputs, add as unsigned words, then narrow to the original width. -/
theorem promoted_add {width promoted : Nat} (bound : width ≤ promoted) (x y : BitVec width) :
    (BitVec.ofInt promoted x.toInt + BitVec.ofInt promoted y.toInt).setWidth width = x + y := by
  rw [← BitVec.ofInt_add, narrow_ofInt bound, BitVec.ofInt_add,
    BitVec.ofInt_toInt, BitVec.ofInt_toInt]

/-- Promote signed inputs, multiply as unsigned words, then narrow. -/
theorem promoted_mul {width promoted : Nat} (bound : width ≤ promoted) (x y : BitVec width) :
    (BitVec.ofInt promoted x.toInt * BitVec.ofInt promoted y.toInt).setWidth width = x * y := by
  rw [← BitVec.ofInt_mul, narrow_ofInt bound, BitVec.ofInt_mul,
    BitVec.ofInt_toInt, BitVec.ofInt_toInt]

/-- Promotion and narrowing also preserve modular subtraction of signed inputs. -/
theorem promoted_sub {width promoted : Nat} (bound : width ≤ promoted) (x y : BitVec width) :
    (BitVec.ofInt promoted x.toInt - BitVec.ofInt promoted y.toInt).setWidth width = x - y := by
  rw [BitVec.sub_eq_add_neg, ← BitVec.ofInt_neg, ← BitVec.ofInt_add,
    narrow_ofInt bound, BitVec.ofInt_add, BitVec.ofInt_neg,
    BitVec.ofInt_toInt, BitVec.ofInt_toInt, ← BitVec.sub_eq_add_neg]

/-- Negation is preserved even at the minimum signed input value. -/
theorem promoted_neg {width promoted : Nat} (bound : width ≤ promoted) (x : BitVec width) :
    (-BitVec.ofInt promoted x.toInt).setWidth width = -x := by
  rw [← BitVec.ofInt_neg, narrow_ofInt bound, BitVec.ofInt_neg, BitVec.ofInt_toInt]

/-- Equal signed observations and equal tensor words are equivalent at one fixed width. -/
theorem tensor_signed_decode_injective {rank : Nat} {shape : Shape rank} {width : Nat}
    (x y : Tensor shape (BitVec width)) :
    Tensor.map BitVec.toInt x = Tensor.map BitVec.toInt y ↔ x = y := by
  constructor
  · intro equal
    funext index
    exact BitVec.eq_of_toInt_eq (congrFun equal index)
  · intro equal
    rw [equal]

end TensorRewrite.Pilot.PromotedWordArithmetic
