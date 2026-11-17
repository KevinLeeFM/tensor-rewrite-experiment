module
public import GatherProof
public section
set_option autoImplicit false
namespace RevisedBenchmark.GatherExact
open TensorRewrite.Pilot.ReducerIndex.GatherLiterals
example : selectedIndex 4 (0 : BitVec 3) = originalIndex 4 (0 : BitVec 3) := by decide
example : selectedIndex 5 (0 : BitVec 3) = 4 ∧ originalIndex 5 (0 : BitVec 3) = 0 := by decide
example : selectedIndex 12 (0 : BitVec 3) = 8 ∧ originalIndex 12 (0 : BitVec 3) = 0 := by decide
example (i : BitVec 8) : selectedIndex 128 i = originalIndex 128 i :=
  (correct 7 128).mpr (by decide) i
example : ¬ (∀ i : BitVec 8, selectedIndex 129 i = originalIndex 129 i) :=
  fun h => (by decide : ¬ 129 ≤ 2^7) ((correct 7 129).mp h)
end RevisedBenchmark.GatherExact
