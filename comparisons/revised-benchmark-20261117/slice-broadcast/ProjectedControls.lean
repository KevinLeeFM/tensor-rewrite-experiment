module
public import ProjectedProof
public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceBroadcast.Controls
open TensorRewrite.Pilot
private def swap : IndexMaps.BroadcastAxes 2 2 :=
  ⟨#v[1,0], by decide⟩
private def straight : IndexMaps.BroadcastAxes 2 2 :=
  ⟨#v[0,1], by decide⟩
private def testPlan (d : IndexMaps.BroadcastAxes 2 2) : Plan 2 2 where
  operand := fun _ => 4
  broadcast := fun _ => 4
  result := fun _ => 2
  dims := d
  matched := fun _ => rfl
  attrs := fun i => if i.val = 0 then ⟨1,4,2⟩ else ⟨0,4,2⟩
  valid := by decide
private def value : Tensor (fun _ : Fin 2 => 4) Nat := fun j => 10 * (j 0).val + (j 1).val
private def pos : Index (fun _ : Fin 2 => 2) := fun i => if i.val = 0 then 1 else 0
example : (testPlan swap).original value pos = 3 := by decide
example : (testPlan straight).original value pos = 30 := by decide
/-- Sorting an unsorted map changes the result even when both descriptors are well typed. -/
example : (testPlan swap).original value ≠ (testPlan straight).original value := by
  intro h
  have eq := congrFun h pos
  exact (by decide : (testPlan swap).original value pos ≠ (testPlan straight).original value pos) eq
private def emptyPlan : Plan 1 1 where
  operand := fun _ => 0
  broadcast := fun _ => 0
  result := fun _ => 0
  dims := ⟨#v[0], by decide⟩
  matched := fun _ => rfl
  attrs := fun _ => ⟨0,0,1⟩
  valid := by decide
example : ∀ i, (emptyPlan.project i).start = 0 ∧ (emptyPlan.project i).stride = 1 ∧
    (emptyPlan.project i).limit = emptyPlan.broadcast (emptyPlan.dims.decode i) := by decide
example (j : Index emptyPlan.result) : False := Nat.not_lt_zero _ (j 0).isLt
/-- The early guard holds while an unmapped axis is actually sliced. -/
private def forwardPlan : Plan 1 2 where
  operand := fun _ => 4
  broadcast := fun _ => 4
  result := fun i => if i.val = 0 then 2 else 4
  dims := ⟨#v[1], by decide⟩
  matched := fun _ => rfl
  attrs := fun i => if i.val = 0 then ⟨1,4,2⟩ else ⟨0,4,1⟩
  valid := by decide
example : ∀ i, (forwardPlan.project i).start = 0 ∧ (forwardPlan.project i).stride = 1 ∧
    (forwardPlan.project i).limit = forwardPlan.broadcast (forwardPlan.dims.decode i) := by decide
private def forwardPoint (i : Fin 2) : Fin (forwardPlan.result i) :=
  if h : i.val = 0 then ⟨1, by change 1 < (if i.val = 0 then 2 else 4); simp [h]⟩ else ⟨3, by change 3 < (if i.val = 0 then 2 else 4); simp [h]⟩
example : forwardPlan.original (fun j => (j 0).val) forwardPoint = 3 := by decide
end RevisedBenchmark.SliceBroadcast.Controls
