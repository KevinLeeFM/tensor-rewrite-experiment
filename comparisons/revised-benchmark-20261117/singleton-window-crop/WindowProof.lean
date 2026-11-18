module
public import WindowSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.SingletonWindow

private theorem axisShape (a : Axis) (h : 0 < output a) (kept : ¬ cut a) :
    0 ≤ start a ∧ start a ≤ stop a ∧ stop a ≤ a.n ∧
    padLo a + (stop a-start a) + padHi a = output a := by
  unfold output at h ⊢
  unfold cut at kept
  unfold start stop padLo padHi
  omega

private theorem align (a : Axis) (y : Int) (lo : 0 ≤ y) (hi : y < output a) :
    (0 ≤ y-a.low ∧ y-a.low < a.n) ↔
    (0 ≤ y-padLo a ∧ y-padLo a < stop a-start a) := by
  unfold output at hi
  unfold padLo start stop
  omega

private theorem index_eq (a : Axis) (y : Int) : start a + (y-padLo a) = y-a.low := by
  unfold start padLo
  omega

private theorem comm (op : Op) (a b : Int) : applyOp op a b = applyOp op b a := by
  cases op <;> simp only [applyOp] <;> omega

theorem verified : Goal := by
  intro r _ ds live
  constructor
  · intro keep d
    apply axisShape _ (live d).2
    intro cutAt
    apply keep
    refine ⟨⟨d, ?_⟩, d, cutAt⟩
    have size := (live d).1
    unfold cut at cutAt
    omega
  · intro y valid op seed x
    unfold old emitted
    by_cases ended : full ds
    · obtain ⟨d, cutAt⟩ := ended.2
      have never : ¬ (∀ j, 0 ≤ y j - (ds j).low ∧ y j - (ds j).low < (ds j).n) := by
        intro each
        have here := each d
        have out := valid d
        unfold cut at cutAt
        unfold output at out
        omega
      simp only [ite_eq_left ended, ite_eq_right never]
    · have same : (∀ d, 0 ≤ y d - (ds d).low ∧ y d - (ds d).low < (ds d).n) ↔
          (∀ d, 0 ≤ y d - padLo (ds d) ∧ y d - padLo (ds d) < stop (ds d) - start (ds d)) :=
        forall_congr' fun d => align (ds d) (y d) (valid d).1 (valid d).2
      simp only [ite_eq_right ended, index_eq, ← same]
      split
      · apply comm
      · rfl

#print axioms verified
end RevisedBenchmark.SingletonWindow
