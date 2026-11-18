import MergeSpec
namespace RevisedBenchmark.MergeAxes

private theorem distribute (xs : List Nat) (a b : Nat → Int) :
    sumOver xs (fun i => a i+b i) = sumOver xs a + sumOver xs b := by
  induction xs with
  | nil => simp [sumOver]
  | cons i xs ih => simp only [sumOver, List.map_cons,List.sum_cons] at *; rw [ih]; omega

private theorem constant (xs : List Nat) (z : Int) :
    sumOver xs (fun _ => z) = (xs.length : Int)*z := by
  induction xs with
  | nil => simp [sumOver]
  | cons i xs ih =>
    simp only [sumOver,List.map_cons,List.sum_cons,List.length_cons,Int.natCast_succ,
      Int.add_mul,Int.one_mul] at *
    omega

private theorem transpose (is js : List Nat) (f : Nat → Nat → Int) :
    sumOver js (fun j => sumOver is (fun i => f i j)) =
    sumOver is (fun i => sumOver js (f i)) := by
  induction is with
  | nil => change sumOver js (fun _ => 0) = 0; rw [constant,Int.mul_zero]
  | cons i is ih =>
    change sumOver js (fun j => f i j + sumOver is (fun u => f u j)) =
      sumOver js (f i) + sumOver is (fun u => sumOver js (f u))
    rw [distribute,ih]

private theorem flat (is js : List Nat) (f : Nat → Nat → Int) :
    ((is.flatMap fun i => js.map fun j => (i,j)).map fun p => f p.1 p.2).sum =
    sumOver is (fun i => sumOver js (f i)) := by
  induction is with
  | nil => rfl
  | cons i is ih =>
    simp only [List.flatMap_cons,List.map_append,List.sum_append, List.map_map,ih]
    rfl

theorem verified : Goal := by
  intro first m n keep x k seed
  constructor
  · cases first <;> decide
  · have eq := flat (List.range m) (List.range n) (fun i j => x i j k)
    cases first <;> simp only [original,merged,Bool.false_eq_true,ite_false,ite_true] <;> rw [eq]
    · rw [distribute,constant,List.length_range]; omega
    · rw [distribute,constant,List.length_range,transpose]; omega

theorem identity (first : Bool) (m n keep : Nat) (x : Tensor) (k : Fin keep) :
    original first m n x k 0 = merged m n x k 0 := by
  simpa using (verified first m n keep x k 0).2
#print axioms verified
#print axioms identity
end RevisedBenchmark.MergeAxes
