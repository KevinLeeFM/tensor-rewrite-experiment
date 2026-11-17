import AxisSpec
set_option autoImplicit false
namespace RevisedBenchmark.BroadcastAxis
open TensorRewrite.Pilot TensorRewrite.PaperComparison.Iota

theorem composed {r m q : Nat} (a : IndexMaps.BroadcastAxes r m) (b : IndexMaps.BroadcastAxes m q) :
    Composed a b := by
  intro ha hb i j less
  rw [composeAxes_decode, composeAxes_decode]
  exact hb _ _ (ha _ _ less)

theorem encoded : EncodedIota := by
  unfold EncodedIota
  intros
  rfl

theorem axisAgreement : AxisAgreement := by
  intro r s k l
  constructor
  · intro eq ⟨j⟩
    by_cases same : k = l
    · exact Or.inl same
    right
    have unit : ∀ u v : Fin r, u ≠ v → (∀ t : Index s, (t u).val = (t v).val) → s u = 1 := by
      intro u v ne agree
      let point : Index s := fun ax =>
        ⟨if ax = u then min 1 (s ax - 1) else 0, by
          have pos := (j ax).isLt
          split <;> omega⟩
      have sep := agree point
      simp [point, Ne.symm ne] at sep
      have pos := (j u).isLt
      omega
    exact ⟨unit k l same eq, unit l k (Ne.symm same) (fun t => (eq t).symm)⟩
  · intro h j
    rcases h ⟨j⟩ with same | ⟨uk,ul⟩
    · rw [same]
    · have bk := (j k).isLt
      have bl := (j l).isLt
      omega

example : ¬ (∀ j : Index (fun _ : Fin 2 => 2), (j 0).val = (j 1).val) := by
  intro h
  have bad := (axisAgreement _ _ _).mp h ⟨fun _ => ⟨0, by decide +revert⟩⟩
  exact (by decide : ¬ ((0 : Fin 2) = 1 ∨ ((2 : Nat) = 1 ∧ (2 : Nat) = 1))) bad
#print axioms composed
#print axioms encoded
#print axioms axisAgreement
end RevisedBenchmark.BroadcastAxis
