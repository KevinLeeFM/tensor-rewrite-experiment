import OrderSpec
set_option autoImplicit false
namespace RevisedBenchmark.ReduceOrders

private def total {α : Type} (xs : List α) (f : α → Int) := (xs.map f).sum
private theorem seed {α : Type} (xs : List α) (f : α → Int) (z : Int) :
    xs.foldl (fun v i => v + f i) z = z + total xs f := by
  induction xs generalizing z with
  | nil => simp [total]
  | cons h t ih => simp [total,ih,Int.add_assoc]

private theorem matrix {α β : Type} (as : List α) (bs : List β) (f : α → β → Int) :
    total (as.flatMap (fun i => bs.map (fun j => (i,j)))) (fun p => f p.1 p.2) =
    total as (fun i => total bs (f i)) := by
  induction as with
  | nil => rfl
  | cons a t ih => simpa [total,List.sum_append,List.map_map,Function.comp_def] using ih

private theorem exchange {α β : Type} (xs : List α) (ys : List β) (f : α → β → Int) :
    total xs (fun x => total ys (f x)) = total ys (fun y => total xs (fun x => f x y)) := by
  have zeros : total ys (fun _ => 0) = 0 := by induction ys <;> simp_all [total]
  have add (g h : β → Int) : total ys (fun y => g y + h y) = total ys g + total ys h := by
    induction ys with
    | nil => rfl
    | cons _ t ih => simp only [total,List.map_cons,List.sum_cons] at *; omega
  induction xs with
  | nil => exact zeros.symm
  | cons x xs ih =>
    change total ys (f x) + total xs _ = total ys (fun y => f x y + total xs _)
    rw [add,ih]

private theorem plane {x a y b : Nat} (u : Input Int x a y b) (z : Int) (i : Fin a) (j : Fin b) :
    (coords y x).foldl (fun acc t => acc + u t.2 i t.1 j) z = direct u z (·+·) i j := by
  unfold direct coords
  rw [seed,seed]
  congr 1
  exact (matrix _ _ (fun q p => u p i q j)).trans
    ((exchange _ _ _).trans (matrix _ _ (fun p q => u p i q j)).symm)

theorem exactIntegers : IntCase := by
  intro x a y b swap u z
  cases swap <;> funext i j <;> apply plane

def witness : Input Nat 2 2 2 3 := fun x _ y _ =>
  if x.val = 0 then 1 else if y.val = 0 then 16777216 else 0

theorem rounded : (¬ FloatCase false) ∧ (¬ FloatCase true) := by
  constructor <;> intro h
  · exact (by decide : 16777216 ≠ 16777218)
      (h 2 2 2 3 witness ⟨0,by decide⟩ ⟨0,by decide⟩ 16777216 16777218 (by decide) (by decide))
  · exact (by decide : 16777216 ≠ 16777218)
      (h 2 2 2 3 witness ⟨0,by decide⟩ ⟨0,by decide⟩ 16777216 16777218 (by decide) (by decide))
#print axioms exactIntegers
#print axioms rounded
end RevisedBenchmark.ReduceOrders
