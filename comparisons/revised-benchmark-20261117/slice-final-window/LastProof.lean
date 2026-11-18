module
public import LastSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceFinalWindow

private theorem keeping (a : Axis) (h : matched a) (yes : keep a = true) :
    a.kernel = 1 ∧ width a = a.input := by
  obtain ⟨_, _, stop, low, high, _⟩ := h
  simp [keep] at yes
  unfold win at *
  omega

private theorem reducing (a : Axis) (h : matched a) (no : keep a = false) :
    width a = 1 ∧ a.kernel = a.input := by
  obtain ⟨k, bounds, eqStop, low, high, yes|⟨one, full⟩⟩ := h
  · simp [no] at yes
  · refine ⟨one, ?_⟩
    unfold width at one
    unfold win at *
    omega

private theorem filterAll (xs : List Nat) (f : Nat → Option Nat)
    (h : ∀ x ∈ xs, f x = some x) : xs.filterMap f = xs := by
  induction xs with
  | nil => rfl
  | cons a t ih => simp [h a (by simp), ih (fun x hx => h x (by simp [hx]))]

private theorem rowKeep (a : Axis) (h : matched a) (yes : keep a = true)
    (y : Nat) (bound : y < a.input) : samples a y = [y] := by
  obtain ⟨k,_⟩ := keeping a h yes
  obtain ⟨_, _, _, low, _, _⟩ := h
  have ep : (((a.start+y+0 : Nat) : Int)-a.low) = (y : Int) := by omega
  have fits : 0 ≤ (y : Int) ∧ (y : Int) < a.input := by omega
  simp only [samples, k, List.range_one, List.filterMap_cons, ep, ite_eq_left fits]
  rfl

private theorem rowReduce (a : Axis) (h : matched a) (no : keep a = false) :
    samples a 0 = List.range a.input := by
  obtain ⟨_, k⟩ := reducing a h no
  obtain ⟨_, _, _, low, _, _⟩ := h
  unfold samples
  rw [k]
  apply filterAll
  intro x hx
  have bound := List.mem_range.mp hx
  have ep : (((a.start+0+x : Nat) : Int)-a.low) = (x : Int) := by omega
  have fits : 0 ≤ (x : Int) ∧ (x : Int) < a.input := by omega
  simp only [ep, ite_eq_left fits, Int.toNat_natCast]

private theorem result (ds : List Axis) (h : ∀ a ∈ ds, matched a) :
    (ds.map width).prod = (reducedShape ds).prod ∧ old ds = reduced ds := by
  induction ds with
  | nil => exact ⟨rfl,rfl⟩
  | cons a t ih =>
    have hit := h a (by simp)
    obtain ⟨sizes, fibers⟩ := ih (fun d hd => h d (by simp [hd]))
    cases k : keep a with
    | true =>
      obtain ⟨_,w⟩ := keeping a hit k
      constructor
      · simpa [reducedShape, k, w] using congrArg (a.input * ·) sizes
      · simp only [old, reduced, k, ite_true, fibers, w, List.flatMap_def]
        apply congrArg List.flatten
        apply List.map_congr_left
        intro y hy
        rw [rowKeep a hit k y (List.mem_range.mp hy)]
    | false =>
      obtain ⟨w,_⟩ := reducing a hit k
      exact ⟨by simpa [reducedShape,k,w] using sizes,
        by simp [old, reduced, k, w, fibers, rowReduce a hit k]⟩

/-- The emitted shorter-rank buffer actually has its declared element count. -/
theorem reducedLength (ds : List Axis) : (reduced ds).length = (reducedShape ds).prod := by
  induction ds with
  | nil => rfl
  | cons a t ih =>
    have constant (xs : List Nat) (n : Nat) : (xs.map (fun _ => n)).sum = xs.length*n := by
      induction xs with
      | nil => simp
      | cons x tail ind => simp [ind, Nat.succ_mul, Nat.add_comm]
    cases k : keep a <;>
      simp [reduced, reducedShape, k, List.length_flatMap, ih, constant]

theorem verified : Goal := by
  intro ds h _ _
  obtain ⟨sizes, rows⟩ := result ds h
  exact ⟨sizes, rows, fun _ _ _ _ => by rw [rows]⟩
#print axioms reducedLength
#print axioms verified
end RevisedBenchmark.SliceFinalWindow
