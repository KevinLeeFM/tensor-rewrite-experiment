import GatherEmptyProof
namespace RevisedBenchmark.GatherEmpty
private def c : Axis := ⟨0,0,.collapsed⟩
private def v : Axis := ⟨0,0,.window⟩
private def w : Axis := ⟨4,2,.window⟩
private def b : Axis := ⟨0,0,.batched⟩
example : Legal [c] [3] := by simp [Legal,c]
example : Interleave (windowWidths [c]) [3] [3] := .idx 3 .nil
example : evaluator [3] = [0,0,0] := by decide
example : evaluator [3] ≠ replacement [3] 1 := by decide
example : evaluator [0,3] = replacement [0,3] 1 := by decide
example : Interleave (windowWidths [v]) [3] [0,3] := .win 0 (.idx 3 .nil)
example : Interleave (windowWidths [c,w]) [3] [3,2] := .idx 3 (.win 2 .nil)
example : Legal [c,w] [3] := by simp [Legal,c,w]
example : Legal [b] [0] := by simp [Legal,b]
example : ¬Legal [b] [3] := by simp [Legal,b]
example : ¬Legal [⟨0,1,.window⟩] [] := by simp [Legal]
example : ¬Legal [⟨2,2,.collapsed⟩] [] := by simp [Legal]
#check (verified : Goal)
end RevisedBenchmark.GatherEmpty
