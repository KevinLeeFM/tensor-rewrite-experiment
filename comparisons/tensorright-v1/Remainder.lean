module

public import TensorRewrite.Theory.RemainderScalar
public import TensorRewrite.Pilot.Tensor

/-! Paper-era truncating integer remainder rules, including signed and zero cases. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Remainder

open Pilot

/-- A signed shift by the divisor preserves remainder when the dividend's sign is unchanged. -/
theorem signed_shift (value divisor : Int)
    (sameSign : if 0 ≤ value then 0 ≤ value + divisor else value + divisor < 0) :
    (value + divisor).tmod divisor = value.tmod divisor := by
  have sameNonnegative : (0 ≤ value + divisor) ↔ (0 ≤ value) := by
    split_ifs at sameSign <;> omega
  have sameMod : (value + divisor) % divisor = value % divisor := by
    simp
  have sameDivisibility : (divisor ∣ value + divisor) ↔ (divisor ∣ value) := by
    rw [Int.dvd_iff_emod_eq_zero, Int.dvd_iff_emod_eq_zero, sameMod]
  simp only [Int.tmod_eq_emod, sameMod, sameDivisibility, sameNonnegative]

/-- `divmod/rule04`: nested truncating remainder is idempotent, including divisor zero. -/
theorem nested {rank : Nat} {shape : Shape rank} (input divisor : Tensor shape Int) :
    Tensor.map₂ Int.tmod (Tensor.map₂ Int.tmod input divisor) divisor =
      Tensor.map₂ Int.tmod input divisor := by
  funext index
  exact Theory.Remainder.integer_nested (input index) (divisor index)

/-- `divmod/rule05`: an Iota coordinate below the divisor is unchanged. -/
theorem bounded_iota {rank : Nat} {shape : Shape rank} (axis : Fin rank) (divisor : Int)
    (sizeBound : (shape axis : Int) ≤ divisor) :
    Tensor.map₂ Int.tmod (fun (index : Index shape) => ((index axis).val : Int))
        (Tensor.constant divisor) =
      (fun (index : Index shape) => ((index axis).val : Int)) := by
  funext index
  change ((index axis).val : Int).tmod divisor = (index axis).val
  apply Int.tmod_eq_of_lt
  · omega
  · have bounded := (index axis).isLt
    omega

/-- `divmod/rule06`: adding a nonnegative divisor leaves an Iota remainder unchanged. -/
theorem shifted_iota {rank : Nat} {shape : Shape rank} (axis : Fin rank) (divisor : Int)
    (nonnegative : 0 ≤ divisor) :
    Tensor.map₂ Int.tmod
        (Tensor.map₂ (· + ·) (fun (index : Index shape) => ((index axis).val : Int))
          (Tensor.constant divisor))
        (Tensor.constant divisor) =
      Tensor.map₂ Int.tmod (fun (index : Index shape) => ((index axis).val : Int))
        (Tensor.constant divisor) := by
  funext index
  change (((index axis).val : Int) + divisor).tmod divisor =
    ((index axis).val : Int).tmod divisor
  apply signed_shift
  have indexNonnegative : (0 : Int) ≤ (index axis).val := by omega
  simp only [indexNonnegative, ↓reduceIte]
  omega

/-- `divmod/rule07`: the paper's same-sign guard validates the scalar remainder rewrite. -/
theorem shifted_scalar {rank : Nat} {shape : Shape rank} (value divisor : Int)
    (sameSign : if 0 ≤ value then 0 ≤ value + divisor else value + divisor < 0) :
    Tensor.map₂ Int.tmod
        (Tensor.map₂ (· + ·) (Tensor.constant (shape := shape) value) (Tensor.constant divisor))
        (Tensor.constant divisor) =
      Tensor.map₂ Int.tmod (Tensor.constant value) (Tensor.constant divisor) := by
  funext index
  exact signed_shift value divisor sameSign

/-- The sign guard is necessary: truncated remainder is not generally shift invariant. -/
theorem unguarded_shift_refuted : ((-2 + 3 : Int).tmod 3) ≠ (-2 : Int).tmod 3 := by
  decide

#print axioms unguarded_shift_refuted
#print axioms signed_shift
#print axioms nested
#print axioms bounded_iota
#print axioms shifted_iota
#print axioms shifted_scalar

end TensorRewrite.PaperComparison.Remainder
