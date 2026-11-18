module
public import MappedSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.ReduceMapped

private def pick : List Axis → (Nat → Nat) → List Nat
  | [], _ => []
  | .reduced _ :: t, f => pick t f
  | .added _ :: t, f => pick t (fun i => f (i+1))
  | .kept _ :: t, f => f 0 :: pick t (fun i => f (i+1))

private theorem shifted (ds : List Axis) (p d : Nat) (f : Nat → Nat) (h : d ≤ p) :
    (emitted ds p d).map f = pick ds (fun i => f (p-d+i)) := by
  induction ds generalizing p d with
  | nil => rfl
  | cons a t ih =>
    have e (i : Nat) : (p+1-d)+i = p-d+(i+1) := by omega
    cases a <;> simp [emitted, pick, ih (p+1) d (by omega), ih (p+1) (d+1) (by omega), e]

private def selectOut : List Axis → List Nat → List Nat
  | [], _ => []
  | .reduced _ :: t, out => selectOut t out
  | .added _ :: t, out => selectOut t out.tail
  | .kept _ :: t, out => out.headD 0 :: selectOut t out.tail

private theorem pickList (ds : List Axis) (out : List Nat) :
    pick ds (fun i => out[i]?.getD 0) = selectOut ds out := by
  induction ds generalizing out with
  | nil => rfl
  | cons a t ih =>
    have step : (fun i => out[i+1]?.getD 0) = (fun i => out.tail[i]?.getD 0) := by
      funext i
      cases out <;> simp
    cases a <;> simp [pick, selectOut, step, ih]
    cases out <;> rfl

private theorem projection (ds : List Axis) (out : List Nat) :
    newOut ds out = selectOut ds out := by
  simp [newOut, shifted, pickList]

private theorem lawful (ds : List Axis) (out : List Nat)
    (h : valid (outputShape (dims ds)) out) :
    valid (outputShape (baseDims ds)) (selectOut ds out) := by
  induction ds generalizing out with
  | nil => trivial
  | cons a t ih =>
    cases a <;> cases out <;>
      simp_all [outputShape, dims, baseDims, selectOut, valid]

private theorem fibers (ds : List Axis) (out : List Nat) :
    (reads (dims ds) out).map (originalRead ds) = reads (baseDims ds) (selectOut ds out) := by
  induction ds generalizing out with
  | nil => rfl
  | cons a t ih =>
    cases a <;> simp [dims, baseDims, reads, originalRead, selectOut, List.map_flatMap,
      List.map_map, Function.comp_def, ← ih]

/-- Shape-only validation also works when there are no output coordinates. -/
theorem selectedExtents (ds : List Axis) :
    newOut ds (outputShape (dims ds)) = outputShape (baseDims ds) := by
  rw [projection]
  induction ds with
  | nil => rfl
  | cons a t ih => cases a <;> simp_all [outputShape, dims, baseDims, selectOut]

/-- Raw emitted axes are ordered and in range, even over empty shapes. -/
theorem legalTargets (ds : List Axis) (p d : Nat) (h : d ≤ p) :
    (emitted ds p d).Pairwise (· < ·) ∧
    ∀ i ∈ emitted ds p d, p-d ≤ i ∧ i < p-d+(outputShape (dims ds)).length := by
  induction ds generalizing p d with
  | nil => simp [emitted]
  | cons a t ih =>
    obtain ⟨ordered, bounds⟩ := ih (p+1) d (by omega)
    have more (i : Nat) (hi : i ∈ emitted t (p+1) d) := bounds i hi
    cases a with
    | reduced n => simpa [emitted, dims, outputShape] using ih (p+1) (d+1) (by omega)
    | added n =>
      refine ⟨ordered, ?_⟩
      intro i hi
      have hi' := more i hi
      change p-d ≤ i ∧ i < p-d+((outputShape (dims t)).length+1)
      omega
    | kept n =>
      simp only [emitted, List.pairwise_cons, List.mem_cons]
      refine ⟨⟨fun i hi => ?_, ordered⟩, ?_⟩
      · have hi' := more i hi
        omega
      · intro i hi
        rcases hi with rfl | hi
        · change p-d ≤ p-d ∧ p-d < p-d+((outputShape (dims t)).length+1)
          omega
        · have hi' := more i hi
          change p-d ≤ i ∧ i < p-d+((outputShape (dims t)).length+1)
          omega

/-- Moving the reduction to mapped base axes preserves every ordered read. -/
theorem verified : Goal := by
  intro ds out h
  rw [projection]
  refine ⟨lawful ds out h, fibers ds out, ?_⟩
  intro α x seed op
  rw [← fibers]
  simp [List.foldl_map]
#print axioms legalTargets
#print axioms selectedExtents
#print axioms verified
end RevisedBenchmark.ReduceMapped
