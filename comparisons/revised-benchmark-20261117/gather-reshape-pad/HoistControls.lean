import HoistProof
open RevisedBenchmark.GatherHoist RevisedBenchmark.GatherReshapePad
private def feature : Axis := ⟨2,1,0,1⟩
private def x (i : Fin 2) (j : Fin 3) (f : Fin 2) := 100*i.val+10*j.val+f.val
private def readAt (s : Int) (k : Fin (extent feature).toNat) :=
  gatherRows (w:=1) (by decide) (reshapeRows (fun i j => padRow feature 999 (x i j))) s 0 k
example : readAt 9 ⟨3,by decide⟩ = 121 := by decide
example : readAt 9 ⟨2,by decide⟩ = 999 := by decide
example : readAt (-2) ⟨1,by decide⟩ = 0 := by decide
example : readAt 3 ⟨1,by decide⟩ ≠ 10 := by decide
#check (verified : Goal)
