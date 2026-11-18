import FactorProof
open RevisedBenchmark.ReshapeBroadcast
private def matchAxis : Match [2,3,4,2] [2,3,8] 3 :=
  ⟨[2],[2],[4,2],[8],rfl,rfl,rfl⟩
private def mapped : ∀ _ : Fin 1, Match [2,3,4,2] [2,3,8] 3 := fun _ => matchAxis
private def at25 : Fin [2,3,8].prod := ⟨25, by decide⟩
example : oldRead mapped at25 (fun idx => idx 0) = 0 := by decide
example : newRead mapped at25 (fun idx => idx 0) ≠ (25 / 3) % 3 := by decide
example : ¬ Nonempty (Fin [2,0,3].prod) := by
  rintro ⟨i⟩
  have h := i.isLt
  simp at h
#check (verified : Goal)
