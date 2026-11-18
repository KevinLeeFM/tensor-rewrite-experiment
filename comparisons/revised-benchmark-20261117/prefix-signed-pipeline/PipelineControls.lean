import PipelineProof
namespace RevisedBenchmark.PrefixPipeline
def chain : List (Stage 3) := [.cast .s64,.view (fun i => i),.cast .u8,.cast .s8]
example : scalar chain (-1) = 255 := by decide
example : scalar (chain.reverse) (-1) = -1 := by decide
example : (old .s64 chain (-1) 2).toNat = 765 := by decide
example : (newValue .s32 ([] : List (Stage 2147483648)) 1 ⟨2147483647,by decide⟩).toNat =
    2147483648 := by decide
end RevisedBenchmark.PrefixPipeline
