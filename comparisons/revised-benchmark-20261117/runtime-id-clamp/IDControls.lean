import IDProof
namespace RevisedBenchmark.IDClamp
example : eligible (bound .replica 4 8) 3 = true ∧ eligible (bound .partition 4 8) 3 = false := by decide
example : original 3 7 ≠ 7 := by decide
example : eligible 1 100 = false := by decide
example : eligible (2^32) 0xffffffff#32 = true := by decide
example : original 0xffffffff#32 0xffffffff#32 = 0xffffffff#32 := by decide
#check (verified : Goal)
end RevisedBenchmark.IDClamp
