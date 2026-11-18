import DivSpec
namespace RevisedBenchmark.Division
open Value
private theorem top : legal 127 := by unfold legal; decide
private theorem tiny : legal (-149) := by unfold legal; decide
theorem reciprocal_refuted : ¬ Reciprocal := by
  intro h
  have q := h (-149) (-149) tiny tiny
  contradiction
theorem fractions_refuted : ¬ Fractions := by
  intro h
  have q := h 127 127 127 127 top top top top
  contradiction
theorem numerator_refuted : ¬ Numerator := by
  intro h
  have q := h 127 127 127 top top top
  contradiction
theorem denominator_refuted : ¬ Denominator := by
  intro h
  have q := h 127 127 127 top top top
  contradiction
#print axioms reciprocal_refuted
#print axioms fractions_refuted
#print axioms numerator_refuted
#print axioms denominator_refuted
end RevisedBenchmark.Division
