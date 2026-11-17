module
public import WordCompareSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.WordCompare
open TensorRewrite.Pilot
theorem sameWord : Self := by
  intro r w sh signed d x
  funext i
  cases d <;> simp [Tensor.map₂,Tensor.constant,cmp,selfResult]

theorem unsignedBoundary : UnsignedBoundary := by
  intro r w sh threshold
  constructor
  · intro h
    funext i
    have test := (h (Tensor.constant 0) i).1
    simp [cmp, key, Tensor.constant] at test
    apply BitVec.eq_of_toNat_eq
    simpa [Tensor.constant] using test
  · intro h
    subst threshold
    intro x i
    simp [lowerBounds,cmp,key,Tensor.constant]

theorem extrema : Extreme := by
  intro w s a b
  by_cases order : key s a ≤ key s b
  · have no : ¬ key s b < key s a := by omega
    simp [cmp,minWord,maxWord,order,no]
  · have no : ¬ key s a < key s b := by omega
    simp [cmp,minWord,maxWord,order,no]

example : cmp true .lt (128#8) (0#8) = true ∧ cmp false .lt (128#8) (0#8) = false := by decide
example : ¬ lowerBounds (1#8) (0#8) := by unfold lowerBounds; decide
example : cmp true .gt (maxWord true (128#8) (1#8)) (128#8) = true ∧
    cmp true .gt (128#8) (1#8) = false := by decide
#print axioms sameWord
#print axioms unsignedBoundary
#print axioms extrema
end RevisedBenchmark.WordCompare
