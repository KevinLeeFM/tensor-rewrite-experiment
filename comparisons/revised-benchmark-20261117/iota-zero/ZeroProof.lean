module
public import ZeroSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.IotaZero
open TensorRewrite.Pilot RevisedBenchmark.DynamicSort
theorem staticBoundary : Static := by
  intro r s k
  constructor
  · intro h ⟨j⟩
    let last : Index s := fun t => ⟨s t - 1, by have := (j t).isLt; omega⟩
    have := h last
    change s k - 1 = 0 at this
    omega
  · intro h j
    have := h ⟨j⟩
    have := (j k).isLt
    omega

theorem runtimeBoundary : Runtime := by
  intro d
  cases d with
  | fixed k =>
    simp only [ne_eq, reduceCtorEq, not_false_eq_true, iff_true]
    intro n h guard i
    change n = k at h
    change (k : Int) ≤ 1 at guard
    have := i.isLt
    omega
  | bounded k =>
    simp only [ne_eq, reduceCtorEq, not_false_eq_true, iff_true]
    intro n h guard i
    change n ≤ k at h
    change (k : Int) ≤ 1 at guard
    have := i.isLt
    omega
  | unbounded =>
    constructor
    · intro h
      have e := h 2 trivial (by decide) ⟨1, by decide⟩
      exact (by decide : (1 : Nat) ≠ 0) e |>.elim
    · intro impossible
      exact (impossible rfl).elim

example : Dim.unbounded.admits 2 ∧ Dim.unbounded.stored ≤ 1 ∧
    (⟨1, by decide⟩ : Fin 2).val ≠ 0 := ⟨trivial, by decide, by decide⟩
#print axioms staticBoundary
#print axioms runtimeBoundary
end RevisedBenchmark.IotaZero
