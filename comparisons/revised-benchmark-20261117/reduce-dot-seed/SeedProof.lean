import SeedSpec
set_option autoImplicit false
namespace RevisedBenchmark.BatchSeed

/-- List-induction version of the finite exchange used by GroupedSums.reduce_dot. -/
private theorem swap {α β : Type} (xs : List α) (ys : List β) (f : α → β → Int) :
    (xs.map (fun x => (ys.map (f x)).sum)).sum =
    (ys.map (fun y => (xs.map (fun x => f x y)).sum)).sum := by
  have zeros : (ys.map (fun _ => (0:Int))).sum = 0 := by induction ys <;> simp_all
  have add (g h : β → Int) : (ys.map (fun y => g y + h y)).sum = (ys.map g).sum + (ys.map h).sum := by
    induction ys with
    | nil => rfl
    | cons _ t ih => simp only [List.map_cons,List.sum_cons] at *; omega
  induction xs with
  | nil => simpa using zeros.symm
  | cons x xs ih =>
    simp only [List.map_cons,List.sum_cons]
    rw [add,ih]

theorem directAt (n k : Nat) (z : Int) (l : L) (r : R) (f : Nat) :
    z + sum n (fun b => oldDot k l r b f) = newDot n k l r f ↔ z = 0 := by
  have h := swap (List.range n) (List.range k) (fun b t => l b f t * r b t)
  change sum n (fun b => oldDot k l r b f) = newDot n k l r f at h
  omega

theorem refuted : ¬ Direct := by
  intro h
  have bad := h 2 2 2 5 (fun _ _ _ => 1) (fun _ _ => 1) 0
  exact (by decide : (9:Int) ≠ 4) bad

theorem residual : Residual := by
  intro n k m z l r
  apply congrArg (z + ·)
  apply Eq.trans (b := sum m (fun f => sum n (fun b => oldDot k l r b f)))
  · exact swap _ _ _
  · apply congrArg List.sum
    apply List.map_inj_left.mpr
    intro f _
    exact swap _ _ _
#print axioms refuted
#print axioms directAt
#print axioms residual
end RevisedBenchmark.BatchSeed
