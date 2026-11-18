import CopyProof
namespace RevisedBenchmark.CopyChain
def direct (n : Nat) : Layout (Fin n) n := ⟨id, id, fun _ => rfl, fun _ => rfl⟩
def flip4 (x : Fin 4) : Fin 4 := ⟨3 - x.val, by omega⟩
theorem twice (x : Fin 4) : flip4 (flip4 x) = x := by
  apply Fin.ext
  simp [flip4]
  omega
def backwards : Layout (Fin 4) 4 := ⟨flip4, flip4, twice, twice⟩
def word (a : Fin 4) := a.val + 3
example : copy (direct 4) backwards word 0 = 6 := by decide
example : copy (direct 4) backwards word 0 ≠ word 0 := by decide
example : copy backwards (direct 4) (copy (direct 4) backwards word) 0 = 3 := by decide
example (mem : Fin 0 → Bool) : copy (direct 0) (direct 0) mem = mem := rfl
#check (verified : Goal)
end RevisedBenchmark.CopyChain
