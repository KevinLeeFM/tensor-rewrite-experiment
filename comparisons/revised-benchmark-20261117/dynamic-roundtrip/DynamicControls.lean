import DynamicProof
open RevisedBenchmark.Roundtrip
private def padded := padToStatic 5 [4,7] (fun i => 10+i.val)
example : padded.1 = [4,7,10,11,12] := by decide
example : sliceToDynamic padded.1 (visibleSize true 5 padded.2) = [4,7] := by decide
example : sliceToDynamic padded.1 (visibleSize false 5 3) ≠ [4,7] := by decide
example : sliceToDynamic padded.1 (visibleSize true 1 padded.2) ≠ [4,7] := by decide
example : (padToStatic 0 ([] : List Nat) (fun _ => 1)).1 = [] := by decide
example : (padToStatic 2 [5,6] (fun _ => 0)).1 = [5,6] := by decide
example : visibleSize true 2147483647 2147483647 = 2147483647 := by decide
example : visibleSize true 2147483648 1 ≠ 1 := by decide
