module
public import MixedProof
public section
set_option autoImplicit false
namespace RevisedBenchmark.ConvMixedSpatial
open ConvPointAxes
private def dims : Sizes := ⟨2,2,1,3⟩
private def y : Four := ⟨1,0,2,1⟩
private def x : Arr (input dims 3) := fun z => 1000*z.val.a + 100*z.val.b + 10*z.val.c + z.val.d
private def v : Arr (kernel dims 3) := fun z => z.val.c+1
example : Legal dims := by unfold Legal; decide
example : Fits y (out dims 3 3) := by decide
example : eval x v (oldTerms dims 3 false false y) = 8726 ∧
    eval x v (newTerms dims 3 3 false y) = 8726 ∧
    eval x v (oldTerms dims 3 true true y) = 4726 ∧
    eval x v (newTerms dims 3 3 true y) = 4726 := by decide
example : eval x v (newTerms dims 3 3 false {y with c:=0}) ≠ 8726 := by decide
example : newPair dims 3 3 true y 0 = (⟨0,1,2,1⟩,⟨0,1,2,0⟩) := by decide
example : packed (out dims 3 3) y = 11 := by decide
-- Equal singleton carry/batch extents are retained by BroadcastSequence.
example : newPair ⟨1,2,1,3⟩ 3 1 true ⟨1,0,0,0⟩ 0 =
    (⟨0,0,0,1⟩,⟨0,1,2,0⟩) := by decide
example : ¬ Fits y (out dims 3 0) ∧ win 4 3 ≠ 1 := by decide
#check (verified : Goal)
end RevisedBenchmark.ConvMixedSpatial
