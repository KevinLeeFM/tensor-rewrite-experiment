import WidthProof
namespace RevisedBenchmark.FullWidth
example : reduce 23 0xff800001#32 = 0xff800001#32 := by decide
example : reduce 23 0x80000000#32 = 0x80000000#32 := by decide
example : reduce 23 1#32 = 1#32 := by decide
example : reduce 22 0x3f800001#32 = 0x3f800000#32 := by decide
example : reduce 22 0x3f800003#32 = 0x3f800004#32 := by decide
example : reduce 22 0x3f800001#32 ≠ 0x3f800001#32 := by decide
#check (verified : Goal)
end RevisedBenchmark.FullWidth
