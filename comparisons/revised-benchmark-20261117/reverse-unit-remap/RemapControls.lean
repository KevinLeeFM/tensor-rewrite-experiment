module
public import RemapProof
public section
set_option autoImplicit false
namespace RevisedBenchmark.ReverseRemap
open TensorRewrite.Pilot BroadcastUnits
private def t : Shape 5 := fun i => #[1,2,1,3,1].toVector[i]
private def mask (j : Fin 5) := decide (j.val = 1 ∨ j.val = 3)
private def point : Index t := fun i => ⟨0, by revert i; decide⟩
private def input : Tensor (keptShape t mask) Nat :=
  fun i => 10 * (i ⟨0, by decide⟩).val + (i ⟨1, by decide⟩).val
example : emitted t mask [3,0,1] = [1,0] := rfl
example : emitted t mask [1] = [0] := rfl
example : Tensor.reverse (Tensor.axisMask [1]) (Reshape.reshapeTensor input t rfl) point = 10 := rfl
example : Reshape.reshapeTensor (Tensor.reverse (fun i => decide (i.val ∈ emitted t mask [1])) input)
    t rfl point = 10 := rfl
/-- Without subtraction, axis 1 is still in range but gives a different value. -/
example : Reshape.reshapeTensor (Tensor.reverse (fun i => decide (i.val = 1)) input) t rfl point = 2 := rfl
/-- An original unit axis can be retained by the descriptor and is still skipped. -/
example : emitted t (fun j => decide (j.val ≠ 4)) [0,2,3] = [3] := rfl
private def emptyT : Shape 2 := fun _ => 0
private def bad (j : Fin 2) := decide (j.val = 0)
/-- Deliberately infeasible as an actual empty-deleted source descriptor: [0] → [0,0].
    Merely requiring omitted axes ≤ 1 and equal counts permits an invalid raw axis. -/
example : LinearIndex.elementCount (keptShape emptyT bad) = LinearIndex.elementCount emptyT := rfl
example : emitted emptyT bad [1] = [(positions bad).length] := rfl
example : ¬ (∀ d ∈ emitted emptyT bad [1], d < (positions bad).length) := by
  intro ok
  have := ok 1 (by decide)
  contradiction
example : emitted emptyT (fun _ => true) [1] = [1] := rfl
example : emitted (fun _ : Fin 0 => 1) (fun _ => false) [] = [] := rfl
end RevisedBenchmark.ReverseRemap
