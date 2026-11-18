module
import FiberProof
set_option autoImplicit false
namespace RevisedBenchmark.ReduceReshape

example : Goal false := dropReshape
example : Goal true := moveReshape

/-- Logical major-to-minor [2,2,3,2]→[2,6,2], keep the outermost
and innermost axes and reduce the middle. Challenges the fiber stride. -/
private def reducedEdit : List Group := [.single 2 true, .edit [3,2] [6] rfl, .single 2 true]
example : fiber (reducedEdit.flatMap (axes false true)) 2 = [12,14,16,18,20,22] := by decide
example : fiber (reducedEdit.flatMap (axes false false)) 2 ≠ [12,13,14,15,16,17] := by decide

/-- [2,3,6]→[2,3,2,3], reduce the middle axis on both sides. -/
private def survivorEdit : List Group := [.edit [6] [3,2] rfl, .single 3 false, .single 2 true]
example : resultShape (survivorEdit.flatMap (axes true false)) = [6,2] := by decide
example : resultShape (survivorEdit.flatMap (axes true true)) = [3,2,2] := by decide
example : fiber (survivorEdit.flatMap (axes true true)) 8 = [20,26,32] := by decide
example : (reduceFlat (survivorEdit.flatMap (axes true false)) id 0
    (fun acc v => 100 * acc + v))[8]? = some 202632 := by decide
example : (reduceFlat (survivorEdit.flatMap (axes true true)) id 0
    (fun acc v => 100 * acc + v))[8]? ≠ some 322620 := by decide

/-- Both zero fibers with observable seeds and empty output tensors. -/
private def zeroEdit : List Group := [.edit [0,2] [3,0] rfl, .single 2 true]
example : reduceFlat (zeroEdit.flatMap (axes false true)) id 7 Nat.add = [7,7] := by decide
example : reduceFlat (zeroEdit.flatMap (axes true false)) id 7 Nat.add = [] := by decide
example : fiber ([] : Axes) 0 = [0] := by decide
example : fiber (([.edit [] [1,1] rfl] : List Group).flatMap (axes false true)) 0 = [0] := by decide
end RevisedBenchmark.ReduceReshape
