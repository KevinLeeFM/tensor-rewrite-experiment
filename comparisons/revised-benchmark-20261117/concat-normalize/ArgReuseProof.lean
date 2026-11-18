module
public import ArgReuseSpec

public section
set_option autoImplicit false
namespace RevisedBenchmark.ArgReuse

private theorem projectStep {n : Nat} (d : Direction) (a b : Value n × Nat) :
    valueStep d a.1 b.1 = (argStep d a b).1 := by
  rcases a with ⟨a, ia⟩
  rcases b with ⟨b, ib⟩
  cases a <;> cases b <;> simp [valueStep, argStep, preferLeft]
  rename_i x y
  cases d with
  | maximum =>
    by_cases h : y < x
    · simp [h]
      apply Fin.ext
      rw [Fin.val_max]
      omega
    · simp [h]
      apply Fin.ext
      rw [Fin.val_max]
      omega
  | minimum =>
    by_cases h : x < y
    · simp [h]
      apply Fin.ext
      rw [Fin.val_min]
      omega
    · simp [h]
      apply Fin.ext
      rw [Fin.val_min]
      omega

private theorem foldProject {n : Nat} {ι : Type} (d : Direction)
    (x : ι → Value n) (idx : ι → Nat) (xs : List ι) (a : Value n × Nat) :
    xs.foldl (fun v i => valueStep d v (x i)) a.1 =
      (xs.foldl (fun p i => argStep d p (x i, idx i)) a).1 := by
  induction xs generalizing a with
  | nil => rfl
  | cons h t ih =>
    simpa only [List.foldl_cons, ← projectStep] using ih (argStep d a (x h, idx h))

/-- The value projection of the sibling matches standalone reduction on all fibers. -/
theorem reuse_arg_extremum : Goal := by
  intro n ri ro s t x fiber axis d
  funext o
  exact foldProject d x (fun i => (i axis).val) (fiber o) (seed n d, 0)

end RevisedBenchmark.ArgReuse
