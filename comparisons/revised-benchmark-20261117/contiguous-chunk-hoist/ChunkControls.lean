import ChunkProof
set_option autoImplicit false
namespace RevisedBenchmark.ChunkHoist
private def swap : Order 2 := ⟨Fin.rev,Fin.rev,Fin.rev_rev,Fin.rev_rev⟩
private def two : Fin 2 → List Nat := fun k => if k.val=0 then [2,3] else [4]
private def sample : Index swap two := by
  intro u
  exact ⟨if u.val=0 then 3 else 1, by revert u; decide⟩
example : List.ofFn (fun k => (two k).prod) = [6,4] ∧
    List.ofFn (fun u => (two (swap.toInput u)).prod) = [4,6] := by decide
example : List.ofFn (expanded sample) = [[(4,3)],[(2,0),(3,1)]] := by decide
example : original sample = 7 ∧ emitted sample = 7 ∧
    pack (List.ofFn (outDigit sample)) = 19 := by decide
example : original sample ≠ pack (List.ofFn (outDigit sample)) := by decide

private def rot : Order 3 where
  toInput i := ⟨(i.val+1)%3, Nat.mod_lt _ (by decide)⟩
  toOutput k := ⟨(k.val+2)%3, Nat.mod_lt _ (by decide)⟩
  leftInv := by decide
  rightInv := by decide
private def three : Fin 3 → List Nat := fun k => if k.val=0 then [2] else if k.val=1 then [3] else [4]
private def sample3 : Index rot three := by
  intro u
  exact ⟨if u.val=0 then 2 else if u.val=1 then 0 else 1, by revert u; decide⟩
example : original sample3 = 20 ∧ emitted sample3 = 20 := by decide
example : pack (List.ofFn fun k => ((three k).prod,(sample3 (rot.toInput k)).val)) = 6 := by decide
example : ¬ Nonempty (Index swap (fun _ => [0,2])) := by
  rintro ⟨i⟩
  have h := (i 0).isLt
  simp at h
example : pack (expand [1,1] 0) = 0 ∧ pack [] = 0 := by decide
#check (verified : Goal)
end RevisedBenchmark.ChunkHoist
