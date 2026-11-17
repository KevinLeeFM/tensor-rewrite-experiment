module
public import RotationSpec

@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.Rotation
open TensorRewrite.Pilot

private theorem cyclic_val {n : Nat} (x : Fin n) (k : Int) :
    ((cyclic x k).val : Int) = ((x.val : Int) + k) % (n : Int) := by
  have hx := x.isLt
  exact Int.toNat_of_nonneg (Int.emod_nonneg _ (by omega))

private theorem cyclic_zero {n : Nat} (x : Fin n) : cyclic x 0 = x := by
  apply Fin.ext
  have hx := x.isLt
  have h := cyclic_val x 0
  rw [Int.add_zero, Int.emod_eq_of_lt (by omega) (by omega)] at h
  omega

private theorem cyclic_add {n : Nat} (x : Fin n) (a b : Int) :
    cyclic (cyclic x a) b = cyclic x (a+b) := by
  apply Fin.ext
  have h := cyclic_val (cyclic x a) b
  rw [cyclic_val x a, Int.emod_add_emod, Int.add_assoc, ← cyclic_val] at h
  omega

private theorem walk_axis {r : Nat} {s : Shape r} (xs : List (Entry r)) (i : Index s) (d : Fin r) :
    walk xs i d = cyclic (i d) (total d xs) := by
  induction xs generalizing i with
  | nil => simp [walk, total, cyclic_zero]
  | cons e es ih =>
    obtain ⟨a,k⟩ := e
    rw [walk, ih]
    by_cases h : d = a <;> simp [total, h, cyclic_add]

private def weight {r : Nat} (s : Shape r) (v : Fin r → Bool) (xs : List (Entry r)) (d : Fin r) :=
  ((canonicalEntry s v xs d).map Prod.snd).getD 0

private theorem sum_emitted {r : Nat} (s : Shape r) (v : Fin r → Bool)
    (xs : List (Entry r)) (axes : List (Fin r)) (hn : axes.Nodup) (d : Fin r) :
    total d (axes.filterMap (canonicalEntry s v xs)) =
      if d ∈ axes then weight s v xs d else 0 := by
  induction axes with
  | nil => simp [total]
  | cons a axes ih =>
    obtain ⟨ha, ht⟩ := List.nodup_cons.mp hn
    have step := ih ht
    by_cases keep : (v a && decide (1 < s a) && (total a xs % (s a : Int) != 0)) = true
    · have he : canonicalEntry s v xs a = some (a, total a xs % (s a : Int)) := ite_eq_left keep
      by_cases h : d = a
      · subst d
        simp [he, total, step, ha, weight]
      · simp [he, total, step, h]
    · have he : canonicalEntry s v xs a = none := ite_eq_right keep
      by_cases h : d = a
      · subst d
        simp [he, step, ha, weight]
      · simp [he, step, h]

private theorem same_coordinate {r : Nat} (s : Shape r) (v : Fin r → Bool)
    (xs : List (Entry r)) (i : Index s) (d : Fin r) (hv : v d = true) :
    walk xs i d = walk (canonical s v xs) i d := by
  rw [walk_axis, walk_axis, canonical, sum_emitted _ _ _ _ (List.nodup_finRange _)]
  simp only [List.mem_finRange, ite_true, weight, canonicalEntry, hv, Bool.true_and]
  have hi := (i d).isLt
  by_cases hsize : 1 < s d
  · by_cases hz : total d xs % (s d : Int) = 0
    · simp [hsize, hz, cyclic_zero]
      apply Fin.ext
      have h := cyclic_val (i d) (total d xs)
      rw [← Int.add_emod_emod, hz, Int.add_zero, Int.emod_eq_of_lt (by omega) (by omega)] at h
      omega
    · simp [hsize, hz]
      apply Fin.ext
      have h := cyclic_val (i d) (total d xs % (s d : Int))
      rw [Int.add_emod_emod, ← cyclic_val] at h
      omega
  · exact Fin.ext (by have := (cyclic (i d) (total d xs)).isLt; omega)

theorem rotation_normalization : Goal := by
  intro r s v α base xs
  funext i
  have h : observe base xs i = observe base (canonical s v xs) i := by
    apply congrArg base
    funext d
    exact same_coordinate s v xs i d.val d.property
  cases hc : canonical s v xs with
  | nil => simpa [replacement, hc, observe, walk] using h
  | cons a as => simpa [replacement, hc] using h

end RevisedBenchmark.Rotation
