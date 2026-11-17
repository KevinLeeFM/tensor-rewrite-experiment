module
public import Goal
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceComposeRank
open TensorRewrite.Pilot TensorRewrite.Pilot.SliceShape TensorRewrite.Pilot.IndexMaps
/-- Logical tensor values are equal under the constructed legal combined slice. -/
def TensorGoal : Prop :=
  ∀ {rank : Nat} {inputShape middleShape outputShape : Shape rank} {α : Type}
    (input : Tensor inputShape α) (inner outer : Fin rank → Axis),
    (∀ i, IsWellFormed (inputShape i) (middleShape i) (inner i)) →
    (∀ i, IsWellFormed (middleShape i) (outputShape i) (outer i)) →
    (∀ i, (inner i).stride = 1) → (∀ i, (outer i).stride = 1) →
    let combined : Fin rank → Axis := fun i =>
      { start := (inner i).start + (outer i).start,
        limit := (inner i).start + (outer i).limit, stride := 1 }
    ∃ (valid : ∀ i, IsWellFormed (inputShape i) (outputShape i) (combined i)),
      ∀ (innerValid : ∀ i, IsWellFormed (inputShape i) (middleShape i) (inner i))
        (outerValid : ∀ i, IsWellFormed (middleShape i) (outputShape i) (outer i)),
        (fun index => input (sliceIndex inner innerValid (sliceIndex outer outerValid index))) =
        (fun index => input (sliceIndex combined valid index))
#print TensorGoal
end RevisedBenchmark.SliceComposeRank
