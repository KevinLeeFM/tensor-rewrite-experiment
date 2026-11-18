import CopySpec
namespace RevisedBenchmark.CopyChain
theorem verified : Goal := by
  intro I α n src mid dst mem
  constructor
  · funext a
    simp [copy, mid.decode_encode]
  · funext a
    simp [copy, mid.decode_encode, src.encode_decode]
#print axioms verified
end RevisedBenchmark.CopyChain
