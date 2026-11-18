import LayoutSpec
namespace RevisedBenchmark.ConvDotOrder

private theorem rows (sw : Bool) (B S : Nat) : Case sw B S ↔
    ∀ (b : Fin B) (s : Fin S), b.val*S+s.val = outputRow sw B S b.val s.val := by
  constructor
  · intro h b s
    simpa [conv, dot] using h b s id 1
  · intro h b s x w
    simp [conv, dot, h b s]

theorem criterion (sw : Bool) (B S : Nat) :
    Case sw B S ↔ sw = false ∨ B ≤ 1 ∨ S ≤ 1 := by
  rw [rows]
  constructor
  · intro h
    cases sw with
    | false => simp
    | true =>
      by_cases hb : B ≤ 1
      · exact Or.inr (Or.inl hb)
      by_cases hs : S ≤ 1
      · exact Or.inr (Or.inr hs)
      have e := h ⟨0,by omega⟩ ⟨1,by omega⟩
      simp [outputRow] at e
      omega
  · intro h b s
    rcases h with rfl | hb | hs
    · simp [outputRow]
    · have h₀ : b.val=0 := by omega
      have h₁ : B=1 := by omega
      cases sw <;> simp [outputRow,h₀,h₁]
    · have h₀ : s.val=0 := by omega
      have h₁ : S=1 := by omega
      cases sw <;> simp [outputRow,h₀,h₁]

theorem refuted : ¬ Case true 2 3 := by rw [criterion]; decide
#print axioms criterion
#print axioms refuted
end RevisedBenchmark.ConvDotOrder
