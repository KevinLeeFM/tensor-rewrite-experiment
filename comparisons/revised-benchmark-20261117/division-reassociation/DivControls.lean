import DivProof
namespace RevisedBenchmark.Division
open Value
example : div (finite (-149)) (finite (-149)) = finite 0 ∧
    mul (finite (-149)) (div (finite 0) (finite (-149))) = infinity := by decide
example : div (mul (finite 127) (finite 127)) (mul (finite 127) (finite 127)) = nan := by decide
example : div (div (finite 127) (finite 127)) (finite 127) = finite (-127) ∧
    div (finite 127) (mul (finite 127) (finite 127)) = zero := by decide
example : div (finite 127) (div (finite 127) (finite 127)) = finite 127 ∧
    div (mul (finite 127) (finite 127)) (finite 127) = infinity := by decide
example : quantize (-150) = zero ∧ quantize (-149) = finite (-149) ∧ quantize 128 = infinity := by decide
example : div (div (finite 3) (finite 2)) (finite 1) =
    div (finite 3) (mul (finite 2) (finite 1)) := by decide
#check (reciprocal_refuted : ¬ Reciprocal)
#check (fractions_refuted : ¬ Fractions)
#check (numerator_refuted : ¬ Numerator)
#check (denominator_refuted : ¬ Denominator)
end RevisedBenchmark.Division
