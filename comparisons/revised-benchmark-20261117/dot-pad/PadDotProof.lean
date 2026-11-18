import PadDotSpec
set_option autoImplicit false
namespace RevisedBenchmark.PadDot

theorem slice_width (a : Axis) : sliced a = a.width := by
  cases a with | mk n l h s =>
    cases n <;> simp [sliced, sliceWidth, limit, extent, body, step]

private theorem distinct (ns : List Nat) : (grid ns).Nodup := by
  induction ns with
  | nil => simp [grid]
  | cons n ns ih =>
    apply List.pairwise_flatMap.mpr
    constructor
    · intro i _
      exact ih.map _ (by intro u v h eq; exact h (List.cons.inj eq).2)
    · apply List.nodup_range.imp
      intro i j h x hx y hy
      obtain ⟨u, _, rfl⟩ := List.mem_map.mp hx
      obtain ⟨v, _, rfl⟩ := List.mem_map.mp hy
      exact fun eq => h (List.cons.inj eq).1

private theorem destination (ds : List Axis) (i : List Nat)
    (hi : i ∈ grid (ds.map Axis.width)) : address ds i ∈ grid (ds.map extent) := by
  induction ds generalizing i with
  | nil => simp [grid, address]
  | cons a ds ih =>
    simp only [List.map_cons, grid, List.mem_flatMap, List.mem_map, List.mem_range] at hi ⊢
    obtain ⟨j, hj, tail, ht, rfl⟩ := hi
    refine ⟨pos a j, ?_, address ds tail, ih _ ht, rfl⟩
    cases a with | mk n l h s =>
      cases n with
      | zero => exact False.elim (Nat.not_lt_zero _ hj)
      | succ k =>
        have le := Nat.mul_le_mul_right (s+1) (Nat.le_of_lt_succ hj)
        simp only [pos, extent, body, step]
        omega

/-- Distinct original coordinates cannot collide in the zero-filled scatter. -/
theorem address_unique (ds : List Axis) (i j : List Nat)
    (hi : i ∈ grid (ds.map Axis.width)) (hj : j ∈ grid (ds.map Axis.width))
    (he : address ds i = address ds j) : i = j := by
  induction ds generalizing i j with
  | nil => simp [grid] at hi hj; simp [hi, hj]
  | cons a ds ih =>
    simp only [List.map_cons, grid, List.mem_flatMap, List.mem_map] at hi hj
    obtain ⟨u, _, us, hus, rfl⟩ := hi
    obtain ⟨v, _, vs, hvs, rfl⟩ := hj
    obtain ⟨hh, ht⟩ := List.cons.inj he
    have hmul := Nat.add_left_cancel hh
    have huv : u = v := Nat.eq_of_mul_eq_mul_right (Nat.zero_lt_succ _) hmul
    rw [huv, ih _ _ hus hvs ht]

private theorem plus {α : Type} (xs : List α) (f g : α → Int) :
    total xs (fun i => f i + g i) = total xs f + total xs g := by
  induction xs with
  | nil => rfl
  | cons i xs ih =>
    simp only [total, List.map_cons, List.sum_cons] at *
    omega

private theorem zeros {α : Type} (xs : List α) : total xs (fun _ => 0) = 0 := by
  induction xs <;> simp_all [total]

private theorem exchange {α β : Type} (xs : List α) (ys : List β) (f : α → β → Int) :
    total xs (fun x => total ys (f x)) = total ys (fun y => total xs (fun x => f x y)) := by
  induction xs with
  | nil => exact (zeros ys).symm
  | cons x xs ih =>
    change total ys (f x) + total xs _ = total ys (fun y => f x y + total xs (fun z => f z y))
    rw [plus, ih]

private theorem factor {α : Type} (xs : List α) (f : α → Int) (y : Int) (b : Bool) :
    times b (total xs f) y = total xs (fun x => times b (f x) y) := by
  induction xs with
  | nil => cases b <;> simp [total, times]
  | cons i xs ih =>
    change times b (f i + total xs f) y = times b (f i) y + total xs _
    rw [← ih]
    cases b <;> simp [times, Int.add_mul, Int.mul_add]

private theorem delta {α : Type} [DecidableEq α] (xs : List α) (p : α) (f : α → Int)
    (hn : xs.Nodup) : total xs (fun k => if p = k then f k else 0) =
      if p ∈ xs then f p else 0 := by
  induction xs with
  | nil => simp [total]
  | cons k xs ih =>
    obtain ⟨hk, ht⟩ := List.nodup_cons.mp hn
    change (if p = k then f k else 0) + total xs _ = _
    rw [ih ht]
    by_cases eq : p = k
    · subst p; simp [hk]
    · simp [eq]

theorem verified : Case := by
  intro ds b x y
  have hw : ds.map sliced = ds.map Axis.width := List.map_inj_left.mpr fun a _ => slice_width a
  unfold original replacement padded
  rw [hw]
  let ids := grid (ds.map Axis.width)
  let ps := grid (ds.map extent)
  change total ps _ = total ids _
  let f := fun (p i : List Nat) => times b (if address ds i = p then x i else 0) (y p)
  have expand : (fun p => times b (total ids (fun i => if address ds i = p then x i else 0))
      (y p)) = (fun p => total ids (f p)) := funext fun p => factor _ _ _ _
  rw [expand, exchange]
  apply congrArg List.sum
  apply List.map_inj_left.mpr
  intro i hi
  have hdelta := delta ps (address ds i) (fun p => times b (x i) (y p)) (distinct _)
  rw [ite_eq_left (destination ds i hi)] at hdelta
  refine Eq.trans ?_ hdelta
  apply congrArg (total ps)
  funext p
  dsimp only [f]
  by_cases h : address ds i = p
  · simp [h]
  · cases b <;> simp [h, times]

example : Case := verified
#print axioms verified
#print axioms address_unique
end RevisedBenchmark.PadDot
