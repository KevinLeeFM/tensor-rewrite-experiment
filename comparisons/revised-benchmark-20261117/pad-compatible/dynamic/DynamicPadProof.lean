module
public import DynamicPadSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.DynamicPad
open RevisedBenchmark.DynamicSort TensorRewrite.Pilot TensorRewrite.PaperComparison.SignedPad

private theorem finiteLength (upper n gap : Nat) (admitted : n ≤ upper)
    (same : extent upper 0 0 gap = (upper : Int)) : extent n 0 0 gap = (n : Int) := by
  simp only [extent, Int.add_zero] at *
  have z : max 0 ((upper : Int) - 1) * gap = 0 := by omega
  rcases Int.mul_eq_zero.mp z with small | zero
  · have : max 0 ((n : Int) - 1) = 0 := by omega
    simp [this]
  · simp [zero]

theorem classify : Classification := by
  intro d gap
  constructor
  · intro uniform
    by_cases ordinary : d ≠ .unbounded
    · exact Or.inl ordinary
    · have h : d = .unbounded := by simpa using ordinary
      subst d
      have guard : candidate .unbounded gap := by simp [candidate, storedOutput, Dim.stored]
      have two := uniform 2 trivial guard
      simp [extent, show max (0 : Int) 1 = 1 by decide, Int.one_mul] at two
      exact Or.inr (by omega)
  · intro condition n adm guard
    rcases condition with finite | zero
    · cases d with
      | fixed upper =>
        change n = upper at adm
        subst n
        exact guard.2.2
      | bounded upper => exact finiteLength upper n gap adm guard.2.2
      | unbounded => exact False.elim (finite rfl)
    · simp [zero, extent]

/-- The local raw guard fires on the unbounded descriptor but not on a
    fixed or bounded length-two descriptor padded with one interior slot. -/
theorem witness : candidate .unbounded 1 ∧ Dim.unbounded.admits 2 ∧
    extent 2 0 0 1 = 3 ∧ (3 : Int) ≠ 2 := by
  simp [candidate, storedOutput, Dim.stored, Dim.admits, extent, show max (0 : Int) 1 = 1 by decide]
example : ¬candidate (.bounded 2) 1 := by simp [candidate, storedOutput, Dim.stored, extent, show max (0 : Int) 1 = 1 by decide]
private def sh (n : Nat) : Shape 1 := fun _ => n
private def padded : Params (sh 2) (sh 3) :=
  ⟨fun _ => 0, fun _ => 0, fun _ => 1, fun _ => by rfl⟩
private def x : Tensor (sh 2) Nat := fun j => 7 + (j 0).val
example : tensor padded 99 x (fun _ => (⟨1, by decide⟩ : Fin 3)) = 99 ∧
    x (fun _ => (⟨1, by decide⟩ : Fin 2)) = 8 := by decide
#print axioms classify
#print axioms witness
end RevisedBenchmark.DynamicPad
