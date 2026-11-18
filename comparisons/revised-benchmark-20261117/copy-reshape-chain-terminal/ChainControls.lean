import ChainProof
open RevisedBenchmark.CopyChain RevisedBenchmark.DenseChain
private def direct (n : Nat) : LayoutN n := ⟨id,id,fun _ => rfl,fun _ => rfl⟩
private def rev (i : Fin 2) : Fin 2 := ⟨1 - i.val, by omega⟩
private theorem twice (i : Fin 2) : rev (rev i) = i := by apply Fin.ext; simp [rev]; omega
private def second : LayoutN 2 := ⟨rev,rev,twice,twice⟩
example : run (direct 2) (direct 2) [second,direct 2,second] Fin.val 1 = 1 := by decide
example : run (direct 2) second [] Fin.val 1 ≠ 1 := by decide
example : copy (direct 2) second Fin.val (second.address 0) = 0 := by decide
example (x : Fin 0 → Bool) : run (direct 0) (direct 0) [] x = x := rfl
#check (raw_verified : ChainGoal)
#check (forward_verified : ForwardGoal)
