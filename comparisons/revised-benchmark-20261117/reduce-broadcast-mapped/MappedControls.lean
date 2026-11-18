module
import MappedProof
set_option autoImplicit false
namespace RevisedBenchmark.ReduceMapped
example : Goal := verified

/-- Target [added, reduced, kept, added, reduced, kept], base [2,3,2,4]. -/
private def ds : List Axis := [.added 5, .reduced 2, .kept 3, .added 7, .reduced 2, .kept 4]
example : emitted ds 0 0 = [1,3] := by decide
example : newOut ds [4,2,6,3] = [2,3] := by decide
example : valid (outputShape (dims ds)) [4,2,6,3] := by
  change 4 < 5 ∧ 2 < 3 ∧ 6 < 7 ∧ 3 < 4 ∧ True
  decide
example : (reads (dims ds) [4,2,6,3]).map (originalRead ds) =
    [[0,2,0,3],[0,2,1,3],[1,2,0,3],[1,2,1,3]] := by decide
/-- Wrong but in-range final target silently changes a legal base coordinate. -/
example : newOut ds [4,2,1,3] ≠ ([1,2].map (fun i : Nat => ([4,2,1,3] : List Nat)[i]?.getD 0)) := by decide
example : reads (baseDims [.added 3,.reduced 0]) (newOut [.added 3,.reduced 0] [2]) = [] := by decide
example : ¬ valid (outputShape (dims [.added 0,.kept 3])) [0,1] := by
  change ¬ (0 < 0 ∧ 1 < 3 ∧ True)
  decide
example : reads (baseDims [.added 3]) (newOut [.added 3] [2]) = [[]] := by decide
example : reads (dims []) [] = [[]] := by decide
end RevisedBenchmark.ReduceMapped
