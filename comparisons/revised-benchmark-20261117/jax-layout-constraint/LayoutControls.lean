import LayoutProof
namespace RevisedBenchmark.LayoutConstraint
open CopyChain
private def normal (n) : Layout (Fin n) n := ⟨id,id,fun _ => rfl,fun _ => rfl⟩
private def flipped : Layout (Fin 2) 2 :=
  ⟨Fin.rev, Fin.rev, Fin.rev_rev, Fin.rev_rev⟩
example : Goal := verified
example : original (normal 2) Fin.val 0 = 0 ∧
          replacement false (normal 2) flipped Fin.val 0 = 0 ∧
          replacement true (normal 2) flipped Fin.val 0 = 1 := by decide
example : replacement true (normal 1) (normal 1) Fin.val 0 = 0 := rfl
example (i : Fin 0) : False := Fin.elim0 i
end RevisedBenchmark.LayoutConstraint
