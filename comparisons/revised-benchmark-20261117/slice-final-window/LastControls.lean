import LastProof
set_option autoImplicit false
namespace RevisedBenchmark.SliceFinalWindow
example : Goal := verified
private def a : Axis := ⟨2,2,1,0,1,2⟩
private def b : Axis := ⟨2,1,0,0,0,2⟩
private def c : Axis := ⟨3,3,2,0,2,3⟩
example : matched a ∧ matched b ∧ matched c := by unfold matched; decide
example : (old [a,b,c])[1]? =
  some [[0,1,0],[0,1,1],[0,1,2],[1,1,0],[1,1,1],[1,1,2]] := by decide
example : reducedShape [a,b,c] = [2] ∧ [a,b,c].map width = [1,2,1] := by decide
example : samples {c with start:=1} 0 = [0,1] := by decide
example : ¬matched {c with start:=1} := by unfold matched; decide
example : ¬matched {c with high:=1} := by unfold matched; decide
example : ¬matched {c with input:=4} := by unfold matched; decide
example : samples {c with low:=0} 0 ≠ List.range 3 := by decide
/-- A legal but earlier width-one slice sees leading padding and misses the final point. -/
example : samples {c with start:=1,stop:=2} 0 = [0,1] ∧
    samples c 0 = [0,1,2] := by decide
example : ∃ d ∈ [a,b,c], d.low ≠ 0 := ⟨a, by simp, by decide⟩
example : ∃ d ∈ [a,b,c], keep d = false := ⟨a, by simp, by decide⟩
end RevisedBenchmark.SliceFinalWindow
