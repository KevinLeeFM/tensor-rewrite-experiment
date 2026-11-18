import PrefixProof
namespace RevisedBenchmark.WideCount
example : original 1 2147483647 = 0x0000000080000000#64 := by rw [originalCount]
example : replacement 1 2147483647 = 0xffffffff80000000#64 := by decide
example : original 1 2147483646 = replacement 1 2147483646 := by rw [originalCount]; decide
example : original 3 2 = replacement 3 2 := by decide
#check (refuted : ¬Goal)
end RevisedBenchmark.WideCount
