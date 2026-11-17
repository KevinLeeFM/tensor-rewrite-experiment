module
import ElementCount
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex Heldout.ShapeBridge Heldout.ElementCount
set_option autoImplicit false
namespace Heldout.ElementCount.Tests

def inputShape : Shape 3 := fun i => if i.val = 0 then 3 else if i.val = 1 then 4 else 6
/-- Redistribute factor 2 from extent 6 to extent 4: [3,4,6] -> [3,8,3]. -/
example : elementCount (setExtent (setExtent inputShape ⟨2, by decide⟩ 3)
    ⟨1, by decide⟩ (2 * (setExtent inputShape ⟨2, by decide⟩ 3) ⟨1, by decide⟩)) = 72 := by decide
example : elementCount inputShape = 72 := by decide
/-- Incorrect split product is rejected rather than silently assumed. -/
example : ¬ (inputShape ⟨2, by decide⟩ = 2 * 4) := by decide
/-- A zero elsewhere keeps the element count zero after redistribution. -/
def emptyOther : Shape 3 := fun i => if i.val = 0 then 0 else if i.val = 1 then 4 else 6
example : elementCount (setExtent (setExtent emptyOther ⟨2, by decide⟩ 3)
    ⟨1, by decide⟩ (2 * (setExtent emptyOther ⟨2, by decide⟩ 3) ⟨1, by decide⟩)) = 0 := by decide
/-- Width zero and positive factor produce an empty split axis. -/
def emptySplit : Shape 3 := fun i => if i.val = 2 then 0 else 4
example : elementCount (setExtent (setExtent emptySplit ⟨2, by decide⟩ 0)
    ⟨1, by decide⟩ (2 * (setExtent emptySplit ⟨2, by decide⟩ 0) ⟨1, by decide⟩)) = 0 := by decide
/-- Zero factors are also covered by the generic theorem, without claiming source reachability. -/
example : elementCount (setExtent (setExtent emptySplit ⟨2, by decide⟩ 3)
    ⟨1, by decide⟩ (0 * (setExtent emptySplit ⟨2, by decide⟩ 3) ⟨1, by decide⟩)) = 0 := by decide
end Heldout.ElementCount.Tests
namespace Heldout.ElementCount.Tests
/-- Reverse a three-axis finite shape, retaining legal inverse maps. -/
def reverseAxis : Fin 3 → Fin 3 := fun i =>
  if i.val = 0 then ⟨2, by decide⟩ else if i.val = 2 then ⟨0, by decide⟩ else i

def reversePermutation : AxisPermutation 3 where
  outputToInput := reverseAxis
  inputToOutput := reverseAxis
  output_input := by decide
  input_output := by decide
example : elementCount (fun i => inputShape (reversePermutation.outputToInput i)) = 72 := by decide
example : elementCount (fun i => emptyOther (reversePermutation.outputToInput i)) = 0 := by decide
/-- Rank-zero permutation preserves the scalar empty-product count. -/
example : elementCount (fun i => (Fin.elim0 : Shape 0) ((AxisPermutation.identity 0).outputToInput i)) = 1 := by decide
/-- Duplicating an axis is not an injective permutation. -/
def duplicateAxis : Fin 3 → Fin 3 := fun _ => ⟨0, by decide⟩
example : ¬ (∀ a b, duplicateAxis a = duplicateAxis b → a = b) := by decide
end Heldout.ElementCount.Tests
