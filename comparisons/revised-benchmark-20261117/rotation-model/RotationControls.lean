module
import RotationProof
set_option autoImplicit false
open TensorRewrite.Pilot RevisedBenchmark.Rotation

private def shape2 : Shape 2 := fun d => if d = 0 then 4 else 3
private def both : Fin 2 → Bool := fun _ => true
private def code (x : Projected shape2 both) : Nat :=
  10 * (x ⟨0,rfl⟩).val + (x ⟨1,rfl⟩).val
private def origin2 : Index shape2 := fun d => if h : d = 0 then
    ⟨2, by simp [shape2, h]⟩ else ⟨0, by simp [shape2, h]⟩
private def nested : List (Entry 2) := [(1,-1),(0,2),(1,-1),(0,-1)]
example : canonical shape2 both nested = [(0,1),(1,1)] := by decide
example : observe code nested origin2 = 31 := by decide
example : replacement code nested origin2 = 31 := by decide
-- A right rotation, or forwarding a live nonidentity rotation, gives a different value.
example : observe code [(0,-1),(1,-1)] origin2 = 12 := by decide
example : observe code nested origin2 ≠ observe code [] origin2 := by decide

private def firstOnly (d : Fin 2) : Bool := d == 0
private def row (x : Projected shape2 firstOnly) : Nat := (x ⟨0,rfl⟩).val
private def cancel : List (Entry 2) := [(1,1),(0,-5),(0,1)]
example : canonical shape2 firstOnly cancel = [] := by decide
example : replacement row cancel origin2 = 2 := by decide
-- Treating the second axis as a splat on a tensor that reads it would be unsound.
example : observe code cancel origin2 ≠ observe code [] origin2 := by decide
example : canonical (fun _ : Fin 2 => 1) both nested = [] := by decide
example : canonical (fun _ : Fin 2 => 0) both nested = [] := by decide
example : ¬ Nonempty (Index (fun _ : Fin 1 => 0)) := fun ⟨i⟩ => Fin.elim0 (i 0)
example : canonical (fun _ : Fin 0 => 0) (fun _ => true) [] = [] := by decide
example : Goal := rotation_normalization
#print axioms RevisedBenchmark.Rotation.rotation_normalization
