import BatchProof
namespace RevisedBenchmark.BatchDot
open NestedDot
example : (¬ Goal true) ∧ (¬ Goal false) := refuted
-- Both coordinates are in range for every axis of the two four-by-four result frames.
private def a : A := fun x => loadMat fun _ _ => x+1
private def b : B := fun _ _ => loadMat fun _ _ => 1
private def c : C := fun z => loadMat fun _ _ => z+1
example : toLeft (a_bc 1 1 a b c) 2 1 0 0 = some 6 ∧
          a_bc 1 1 a b c 2 1 0 0 = some 3 := by decide
example : toRight (ab_c 1 1 a b c) 1 0 2 0 = some 6 ∧
          ab_c 1 1 a b c 1 0 2 0 = some 2 := by decide
example : 9 * leftCost 1 1 1 1 ≤ 2*(9 * rightCost 1 1 1 1) := by decide
end RevisedBenchmark.BatchDot
