import TriangleSpec
import MergeProof
set_option autoImplicit false
namespace RevisedBenchmark.Triangle
open MergeAxes (sumOver)

private theorem sum_mul (ks : List Nat) (f : Nat → Int) (v : Int) :
    sumOver ks f * v = sumOver ks (fun k => f k * v) := by
  induction ks with
  | nil => simp [sumOver]
  | cons k ks ih => simp only [sumOver, List.map_cons, List.sum_cons, Int.add_mul] at *; rw [ih]

private theorem mul_sum (v : Int) (ks : List Nat) (f : Nat → Int) :
    v * sumOver ks f = sumOver ks (fun k => v * f k) := by
  induction ks with
  | nil => simp [sumOver]
  | cons k ks ih => simp only [sumOver, List.map_cons, List.sum_cons, Int.mul_add] at *; rw [ih]

/-- Both old reduction orientations have the same merged row-major sum at seed zero. -/
private theorem exchange (m n : Nat) (f : Nat → Nat → Int) :
    (sumOver (List.range n) fun j => sumOver (List.range m) fun i => f i j) =
     sumOver (List.range m) fun i => sumOver (List.range n) fun j => f i j := by
  let x : MergeAxes.Tensor := fun i j _ => f i j
  have h := (MergeAxes.identity true m n 1 x 0).trans (MergeAxes.identity false m n 1 x 0).symm
  simpa only [MergeAxes.original, Bool.false_eq_true, ite_false, ite_true, Int.zero_add, x] using h

theorem verified : Goal := by
  intro m n p ni nj nk a b c x y z
  simp only [left, right, sum_mul, mul_sum, Int.mul_assoc]
  calc
    _ = sumOver (List.range nj) (fun j => sumOver (List.range ni) fun i =>
          sumOver (List.range nk) fun k => a x i j * (b i k y * c j k z)) := by
      apply congrArg (sumOver (List.range nj))
      funext j
      exact exchange ni nk (fun i k => a x i j * (b i k y * c j k z))
    _ = _ := exchange ni nj _
#print axioms verified
end RevisedBenchmark.Triangle
