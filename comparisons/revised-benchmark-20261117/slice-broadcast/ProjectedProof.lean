module
public import ProjectedSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceBroadcast
open TensorRewrite.Pilot

/-- Recompute the projected shape, certify the descriptor, and commute the two logical maps. -/
theorem broadcast_sink : Sink := by
  intro m n p
  have e (i : Fin m) : p.inner i = p.result (p.dims.decode i) := by
    unfold Plan.inner Plan.project
    rw [(p.valid (p.dims.decode i)).2.2.2.2.2]
    exact Int.toNat_natCast _
  have v (i : Fin m) : SliceShape.IsWellFormed (p.operand i) (p.inner i) (p.project i) := by
    rw [p.matched i, e i]
    exact p.valid _
  refine ⟨v, e, ?_⟩
  intro α x
  funext j
  apply congrArg x
  funext i
  apply Fin.ext
  rfl

/-- Every coordinate on a mapped axis is fixed by the full unit-step Slice. -/
theorem only_broadcast : Only := by
  intro m n p g
  have e (i : Fin m) : p.operand i = p.result (p.dims.decode i) := by
    rw [p.matched i]
    have h := (p.valid (p.dims.decode i)).2.2.2.2.2
    change (p.project i).elementCount = _ at h
    apply Int.ofNat_inj.mp
    simpa [SliceShape.Axis.elementCount, (g i).1, (g i).2.1, (g i).2.2] using h
  refine ⟨e, ?_⟩
  intro α x
  funext j
  apply congrArg x
  funext i
  apply Fin.ext
  change ((p.project i).start + (p.project i).stride * (j (p.dims.decode i) : Int)).toNat = _
  simp [(g i).1, (g i).2.1, IndexMaps.broadcastIndex]
#check (broadcast_sink : Sink)
#check (only_broadcast : Only)
#print axioms broadcast_sink
#print axioms only_broadcast
end RevisedBenchmark.SliceBroadcast
