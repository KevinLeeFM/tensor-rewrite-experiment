import ReorderProof
open RevisedBenchmark.CopyChain RevisedBenchmark.CopyReshape
private def straight : Dense 2 := ⟨id,id,fun _ => rfl,fun _ => rfl⟩
private def swap (x : Fin 2) : Fin 2 := if x = 0 then 1 else 0
private theorem inv (x : Fin 2) : swap (swap x) = x := by
  have e : x = 0 ∨ x = 1 := by omega
  rcases e with rfl | rfl <;> decide
private def reverseOrder : Dense 2 := ⟨swap,swap,inv,inv⟩
example : old true straight reverseOrder reverseOrder straight Fin.val 0 =
    replacement true true true straight reverseOrder straight straight Fin.val 0 := by decide
example : old false straight straight reverseOrder straight Fin.val 0 ≠
    replacement false false true straight straight reverseOrder straight Fin.val 0 := by decide
example : old false straight straight straight reverseOrder Fin.val 0 =
    replacement false false false straight straight straight reverseOrder Fin.val 0 := by decide
#check (RevisedBenchmark.CopyReshape.verified : RevisedBenchmark.CopyReshape.Goal)
