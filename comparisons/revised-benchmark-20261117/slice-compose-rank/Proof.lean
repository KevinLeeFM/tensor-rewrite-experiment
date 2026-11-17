module
public import Goal
public import StaticProof
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceComposeRank
open TensorRewrite.Pilot TensorRewrite.Pilot.SliceShape TensorRewrite.Pilot.IndexMaps
/-- The frozen arbitrary-rank index-map goal. -/
theorem correctness : Goal := by
  intro rank inputShape middleShape outputShape inner outer hi ho his hos
  let combined : Fin rank → Axis := fun i =>
    { start := (inner i).start + (outer i).start,
      limit := (inner i).start + (outer i).limit, stride := 1 }
  have valid : ∀ i, IsWellFormed (inputShape i) (outputShape i) (combined i) :=
    fun i => SliceComposeStatic.validity _ _ _ _ _ (hi i) (ho i) (his i) (hos i)
  refine ⟨valid, ?_⟩
  intro innerValid outerValid index
  funext i
  apply Fin.ext
  apply Int.ofNat_inj.mp
  rw [sliceIndex_val, sliceIndex_val, sliceIndex_val]
  simp [his i, hos i, Int.add_assoc]
#print axioms correctness
end RevisedBenchmark.SliceComposeRank
