module
public import LiteralSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.Literal

private theorem adjacentCopies {α : Type} [DecidableEq α] (a : α) (xs : List α)
    (h : adjacent (a :: xs) = true) : a :: xs = List.replicate (xs.length+1) a := by
  induction xs generalizing a with
  | nil => rfl
  | cons b tail ih =>
    obtain ⟨hab, ht⟩ := Bool.and_eq_true_iff.mp h
    have eq : a = b := of_decide_eq_true hab
    subst b
    rw [List.replicate_succ]
    exact congrArg (List.cons a) (ih a ht)

/-- Broadcast the actual first stored scalar into every cell of the unchanged shape. -/
theorem uniform : Uniform := by
  intro α inst dims xs hlen hsize h
  cases xs with
  | nil => simp at hlen; omega
  | cons a tail =>
    apply congrArg (Prod.mk dims)
    unfold broadcastFirst
    rw [← hlen]
    exact adjacentCopies a tail h

private theorem scanValues {α : Type} [DecidableEq α] (f : Nat → α) (xs : List α)
    (k : Nat) (h : scan f k xs = true) :
    xs = (List.range xs.length).map (fun i => f (k+i)) := by
  induction xs generalizing k with
  | nil => rfl
  | cons x tail ih =>
    obtain ⟨hx, ht⟩ := Bool.and_eq_true_iff.mp h
    have eq : x = f k := of_decide_eq_true hx
    rw [List.length_cons, List.range_succ_eq_map, List.map_cons, List.map_map]
    simp only [Nat.add_zero, Function.comp_def]
    rw [eq]
    apply congrArg (List.cons (f k))
    simpa only [Nat.succ_add, Nat.add_succ] using ih (k+1) ht

/-- Recognized rank-one literal equals a newly enumerated iota in its element encoding. -/
theorem plain : Iota := by
  intro α inst encode xs _ _ h
  apply congrArg (Prod.mk [xs.length])
  simpa [iota] using scanValues encode xs 0 h

/-- Multiply an independently enumerated integer iota by the actual recognized stride. -/
theorem strided : Strided := by
  intro xs s h
  match xs with
  | [] | [_] => simp [stride?] at h
  | x :: t :: tail =>
    simp only [stride?] at h
    split at h
    · contradiction
    split at h
    · rename_i hs
      obtain rfl := Option.some.inj h
      apply congrArg (Prod.mk [(x :: t :: tail).length])
      simpa only [Nat.zero_add, iota, List.map_map, Function.comp_def] using
        scanValues (fun k => Int.ofNat k * t) (x :: t :: tail) 0 hs
    · contradiction

example : adjacent ([7,7,7,7] : List Int) = true ∧
    broadcastFirst [2,2] [7,7,7,7] = [7,7,7,7] := by decide
example : adjacent ([7,7,9,7] : List Int) = false := by decide
example : ¬ 1 < ([3,0,4] : List Nat).prod ∧ ¬ 1 < ([] : List Nat).prod := by decide
example : scan Int.ofNat 0 [0,1] = true ∧ adjacent ([0,1] : List Int) = false := by decide
example : stride? [0,-3,-6,-9] = some (-3) ∧
    (iota Int.ofNat 4).map (fun x => x * (-3)) ≠ [0,-3,-6,-8] := by decide
example : stride? [0,-3,-6,-8] = none ∧ stride? [0,1,2] = none ∧
    stride? [0,0,0] = none ∧ stride? [0] = none ∧ stride? [] = none := by decide

#check (uniform : Uniform)
#check (plain : Iota)
#check (strided : Strided)
#print axioms uniform
#print axioms plain
#print axioms strided
end RevisedBenchmark.Literal
