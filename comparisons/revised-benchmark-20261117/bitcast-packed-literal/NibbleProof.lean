module
public import NibbleSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.BitcastPacked

theorem verified : Goal := by
  refine ⟨by unfold contiguous; decide,by decide,by decide,?_⟩
  intro order
  constructor
  · intro h
    have witness := h 1 1
    cases order <;> contradiction
  · intro b
    cases order <;> simp [oldSplit,newSplit,rawCopy,literalBytes,packedShape,bytesFor]

#print axioms verified
end RevisedBenchmark.BitcastPacked
