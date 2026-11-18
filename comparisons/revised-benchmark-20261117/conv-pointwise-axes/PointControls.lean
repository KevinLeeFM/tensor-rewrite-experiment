import PointProof
set_option autoImplicit false
namespace RevisedBenchmark.ConvPointAxes

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

private def s : Sizes := ⟨3,4,1,5⟩
private def y : Coord := place out 1 2 3
private def x : Tensor (lhsShape s lhs) := fun i => 100*i.val 0+10*i.val 1+i.val 2
private def w : Tensor (rhsShape s rhs) := fun i => 1+i.val 0
example : Legal s := by unfold Legal; decide
example : Fits (outShape s out) y := by unfold Fits; decide
example : doConv s lhs rhs out y x w = 936 ∧ product s lhs rhs out y x w = 936 := by decide
example : Fits (lhsShape s lhs) y := by unfold Fits; decide
example : read x y * read w (newK s rhs out y) ≠ product s lhs rhs out y x w := by decide
example : read x (inverseRead lhs out y) * read w (place rhs 0 1 0) ≠
    product s lhs rhs out y x w := by decide
example : permutation lhs out 0 = 1 ∧ permutation rhs out 0 = 2 := by decide
example : ¬Legal ⟨6,1,2,5⟩ ∧ ¬Legal ⟨6,4,2,5⟩ := by unfold Legal; decide
example : Legal ⟨0,1,1,0⟩ := by unfold Legal; decide
example : ¬Fits (outShape ⟨0,1,1,0⟩ out) (place out 0 0 0) := by unfold Fits; decide
example : newK ⟨1,1,1,1⟩ rhs out (place out 0 0 0) 0 = 0 := by decide
/-- Singleton output feature is retained by BroadcastSequence when equal,
while the mismatching singleton batch and spatial dimensions are squeezed. -/
example : retained (place out 1 1 1) (place out 3 1 2) (List.finRange 3) = [1] := by decide
example : retained (place out 1 1 1) (place out 1 1 1) (List.finRange 3) = [0,1,2] := by decide
#check (verified : Goal)
end RevisedBenchmark.ConvPointAxes
