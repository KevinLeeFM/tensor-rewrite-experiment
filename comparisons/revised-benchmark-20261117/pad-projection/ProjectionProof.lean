module
public import ProjectionSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.PadProjection
open TensorRewrite.Pilot TensorRewrite.Theory TensorRewrite.PaperComparison.SignedPad

private theorem untouched {r : Nat} {s o : Shape r} (p : Params s o) (j : Index o)
    (d : Fin r) (absent : d ∉ retained p) :
    (sample (s d) (p.low d) (p.interior d) (j d).val).isSome := by
  have attrs : p.low d = 0 ∧ p.high d = 0 ∧ p.interior d = 0 := by
    simpa [retained] using absent
  obtain ⟨lo, hi, gap⟩ := attrs
  have shape := p.shape d
  simp [extent, lo, hi, gap] at shape
  have bound := (j d).isLt
  let idx : Fin (s d) := ⟨(j d).val, by omega⟩
  rw [(sample_some _ _ _ _ idx).mpr (by simp [lo, gap, idx])]
  rfl

theorem correct : Goal := by
  intro r n s o p b contained α fill x
  funext j
  let test := fun d => sample (s d) (p.low d) (p.interior d) (j d).val
  have back (good : ∀ k, (test (axis p k)).isSome = true) :
      ∀ d, (test d).isSome = true := by
    intro d
    by_cases mem : d ∈ retained p
    · have h := good (slot p d mem)
      rwa [atSlot] at h
    · exact untouched p j d mem
  by_cases full : ∀ d, (test d).isSome = true
  · let original : Index s := fun d => (test d).get (full d)
    have left : selected p j = some original :=
      (LatticeIndex.assemble_eq_some_iff _ _).mpr (fun d => (Option.some_get (full d)).symm)
    have right : selected (smaller p) (fun k => j (axis p k)) =
        some (fun k => original (axis p k)) :=
      (LatticeIndex.assemble_eq_some_iff _ _).mpr
        (fun k => (Option.some_get (full (axis p k))).symm)
    simp only [tensor, left, right]
    apply congrArg x
    funext a
    apply Fin.ext
    exact congrArg (fun d => (original d).val) (atSlot p (b a) (contained a)).symm
  · have noneOf {q : Nat} {a z : Shape q} (cfg : Params a z) (v : Index z)
        (missing : ¬ ∀ d, (sample (a d) (cfg.low d) (cfg.interior d) (v d).val).isSome = true) :
        selected cfg v = none := by
      unfold selected LatticeIndex.assemble?
      exact dite_eq_right missing
    have left := noneOf p j full
    have right := noneOf (smaller p) (fun k => j (axis p k)) (fun h => full (back h))
    simp only [tensor, left, right]
#print axioms correct
end RevisedBenchmark.PadProjection
