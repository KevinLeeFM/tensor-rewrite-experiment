module
public import TensorRewrite.Pilot.IndexMapLemmas
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceComposeRank
open TensorRewrite.Pilot TensorRewrite.Pilot.SliceShape TensorRewrite.Pilot.IndexMaps
/-- Construct the combined validity witness and equate actual bounded indices. -/
def Goal : Prop :=
  ∀ {rank : Nat} {inputShape middleShape outputShape : Shape rank}
    (inner outer : Fin rank → Axis),
    (∀ i, IsWellFormed (inputShape i) (middleShape i) (inner i)) →
    (∀ i, IsWellFormed (middleShape i) (outputShape i) (outer i)) →
    (∀ i, (inner i).stride = 1) → (∀ i, (outer i).stride = 1) →
    let combined : Fin rank → Axis := fun i =>
      { start := (inner i).start + (outer i).start,
        limit := (inner i).start + (outer i).limit, stride := 1 }
    ∃ (valid : ∀ i, IsWellFormed (inputShape i) (outputShape i) (combined i)),
      ∀ (innerValid : ∀ i, IsWellFormed (inputShape i) (middleShape i) (inner i))
        (outerValid : ∀ i, IsWellFormed (middleShape i) (outputShape i) (outer i))
        (index : Index outputShape),
        sliceIndex inner innerValid (sliceIndex outer outerValid index) = sliceIndex combined valid index
#print Goal
end RevisedBenchmark.SliceComposeRank
