import RngSpec
namespace RevisedBenchmark.RandomShape
private theorem exchange {α β : Type} (xs : List α) (ys : List β) (f : α → β → Nat) :
    (xs.map (fun x => (ys.map (f x)).prod)).prod =
    (ys.map (fun y => (xs.map (fun x => f x y)).prod)).prod := by
  have units : (ys.map (fun _ => 1)).prod = (1 : Nat) := by induction ys <;> simp_all
  have combine (g h : β → Nat) :
      (ys.map (fun y => g y * h y)).prod = (ys.map g).prod * (ys.map h).prod := by
    clear units
    induction ys with
    | nil => rfl
    | cons y ys ih => simp only [List.map_cons, List.prod_cons, ih]; ac_rfl
  induction xs with
  | nil => simpa using units.symm
  | cons x xs ih =>
    simp only [List.map_cons, List.prod_cons]
    rw [combine, ih]
theorem transposeLaw : Law := by
  intro r c w positive b
  apply Prod.ext
  · exact exchange _ _ _
  · simp [total, Nat.mul_comm]
theorem oldCoordinatesValid {r c u v : Nat} (same : r*c = u*v) (i : Fin u) (j : Fin v) :
    (i.val*v+j.val)/c < r ∧ (i.val*v+j.val)%c < c := by
  have h := Nat.mul_le_mul_right v (Nat.succ_le_of_lt i.isLt)
  rw [Nat.succ_mul] at h
  have k : i.val*v+j.val < r*c := by omega
  have hc : 0 < c := by
    cases c with
    | zero => simp at k
    | succ => omega
  exact ⟨(Nat.div_lt_iff_lt_mul hc).mpr k, Nat.mod_lt _ hc⟩
theorem reshapeStream : Reshape := by
  intro α stream r c u v size i j
  simp only [oldReshape]
  apply congrArg stream
  rw [Nat.mul_comm (_ / _), Nat.div_add_mod]
theorem differentSeedObservation : ¬ SameSeedTranspose := by
  intro h
  have b := h (fun k => k == 1) 2 2 0 1
  contradiction
#print axioms transposeLaw
#print axioms reshapeStream
#print axioms differentSeedObservation
end RevisedBenchmark.RandomShape
