import TapProof
set_option autoImplicit false
namespace RevisedBenchmark.ConvFullTaps
open ConvPointAxes
private def out : Order where
  slot | .batch => 0 | .feature => 1 | .space => 2
  role p := if p=0 then .batch else if p=1 then .feature else .space
  slot_role := by decide
  role_slot := by intro a; cases a <;> rfl
private def lhs : Order where
  slot | .batch => 1 | .feature => 2 | .space => 0
  role p := if p=0 then .space else if p=1 then .batch else .feature
  slot_role := by decide
  role_slot := by intro a; cases a <;> rfl
private def rhs : Order where
  slot | .batch => 2 | .feature => 0 | .space => 1
  role p := if p=0 then .feature else if p=1 then .space else .batch
  slot_role := by decide
  role_slot := by intro a; cases a <;> rfl

private def s : Sizes := ⟨2,3,1,3⟩
private def y : Coord := place out 1 2 0
private def x : Tensor (lhsShape s lhs) := fun i => 10*i.val 0+i.val 1+i.val 2
private def weights : Tensor (kernelShape s 3 rhs) := fun i => 100*i.val 0+i.val 1+1
example : Fits (finalShape s 3 out) y := by unfold Fits; decide
example : Legal s := by unfold Legal; decide
example : win s.spatial 3 = 1 ∧ win 2 3 ≠ 1 ∧ win 4 3 ≠ 1 := by decide
example : contract x weights (oldTerms s 3 lhs rhs out false y) = 7898 := by decide
example : contract x weights (newTerms s 3 lhs rhs out false y) = 7898 := by decide
example : contract x weights (oldTerms s 3 lhs rhs out true y) = 7858 := by decide
example : contract x weights (newTerms s 3 lhs rhs out true y) = 7858 := by decide
example : deleted rhs = [0,2] := by decide
example : ¬ Fits (finalShape ⟨0,1,1,3⟩ 3 out) (place out 0 0 0) := by unfold Fits; decide
example : pack (finalShape s 3 rhs) (place rhs 1 2 0) 0 (List.finRange 3) = 5 ∧
    pack (lhsShape s rhs) (place rhs 1 2 0) 0 (deleted rhs) = 5 := by decide
example : ¬ Legal ⟨4,2,2,3⟩ := by unfold Legal; decide
#check (verified : Goal)
end RevisedBenchmark.ConvFullTaps
