import TriangleProof
set_option autoImplicit false
namespace RevisedBenchmark.Triangle
open MergeAxes (sumOver)
private def a : Array3 := fun _ i j => if i = j then 1 else 0
private def b : Array3 := fun i k _ => if i = k then 1 else 0
private def c : Array3 := fun j k _ => if j = k then (if j = 0 then -2 else 5) else 12
example : Goal := verified
example : left 2 2 2 a b c 0 0 0 = 3 ∧ right 2 2 2 a b c 0 0 0 = 3 := by decide
-- Select the opposite AC coordinate for the replacement instead of the shared j.
example : right 2 2 2 a b (fun j k z => c (1-j) k z) 0 0 0 = 24 := by decide
example : left 2 0 2 a b c 0 0 0 = 0 ∧ right 2 0 2 a b c 0 0 0 = 0 := by decide
-- M=16, I=2, J=3, K=8, N=3, P=2. Both old and new result shapes are [16,3,2].
example : 2*(16*3*8*3*2 + 16*3*2*3*8) > 2*(2*(2*3*3*2*8 + 16*3*2*2*3)) := by decide
end RevisedBenchmark.Triangle
