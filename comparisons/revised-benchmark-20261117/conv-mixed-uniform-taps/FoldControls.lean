import FoldProof
namespace RevisedBenchmark.MixedTapCount
example : old true 66052 (value .byte) (value .byte) = 4294967295#32 := by rw [foldOld]; decide
example : newValue true 66052 (value .byte) (value .byte) = 64004#32 := by rw [foldNew]; decide
example : old false 66051 (value .byte) (value .byte) =
  newValue false 66051 (value .byte) (value .byte) := by rw [foldOld,foldNew]; decide
end RevisedBenchmark.MixedTapCount
