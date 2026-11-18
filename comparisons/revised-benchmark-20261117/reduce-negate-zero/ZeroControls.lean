import ZeroProof
namespace RevisedBenchmark.NegatedReduction
example : oldBits true [false, true] = 0#32 := by decide
example : newBits true [false, true] = 0x80000000#32 := by decide
example : oldBits true [true, true] = newBits true [true, true] := by decide
example : oldBits true [false, false] = newBits true [false, false] := by decide
#check (refuted : ¬ Preserves)
end RevisedBenchmark.NegatedReduction
