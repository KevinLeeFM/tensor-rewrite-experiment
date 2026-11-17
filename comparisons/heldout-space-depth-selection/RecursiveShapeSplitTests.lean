module
import RecursiveShapeSplit
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.FiniteProduct Heldout.RecursiveShapeSplit
set_option autoImplicit false

/-- A three-dimensional nonempty full shape and its last index. -/
def sampleShape : Shape 3 := fun i => if i.val = 0 then 2 else if i.val = 1 then 3 else 4
def sampleIndex : Index sampleShape := fun i =>
  ⟨if i.val = 0 then 1 else if i.val = 1 then 2 else 3,
    (show ∀ i : Fin 3, (if i.val = 0 then 1 else if i.val = 1 then 2 else 3) < sampleShape i by decide) i⟩
example : elementCount (preShape (m := 1) (n := 2) sampleShape) = 2 := by decide
example : elementCount (tailShape (m := 1) (n := 2) sampleShape) = 12 := by decide
example : (linearize sampleShape sampleIndex).val = 23 := by decide
example : (join (linearize (preShape (m := 1) (n := 2) sampleShape) (preIndex (m := 1) (n := 2) sampleIndex))
  (linearize (tailShape (m := 1) (n := 2) sampleShape) (tailIndex (m := 1) (n := 2) sampleIndex))).val = 23 := by decide
example := full_linearize_split (m := 1) (n := 2) sampleIndex

/-- Empty prefix and empty tail at scalar rank. -/
def scalarShape : Shape 0 := fun i => Fin.elim0 i
def scalarIndex : Index scalarShape := fun i => Fin.elim0 i
example := full_linearize_split (m := 0) (n := 0) scalarIndex

/-- Zero extents remain zero in the product and exclude full coordinates. -/
def emptyShape : Shape 2 := fun i => if i.val = 0 then 0 else 3
example : elementCount emptyShape = 0 := by decide
example := full_count_split (m := 1) (n := 1) emptyShape
example : ¬ Nonempty (Index emptyShape) := by
  intro ⟨index⟩
  exact Fin.elim0 (index ⟨0, by decide⟩)
/-- Reversing prefix and tail changes the packed coordinate on a concrete input. -/
def wrongIndex : Index sampleShape := fun i =>
  ⟨if i.val = 0 then 1 else 0,
    (show ∀ i : Fin 3, (if i.val = 0 then 1 else 0) < sampleShape i by decide) i⟩
example : (linearize sampleShape wrongIndex).val = 12 := by decide
example : (join (linearize (tailShape (m := 1) (n := 2) sampleShape) (tailIndex (m := 1) (n := 2) wrongIndex))
      (linearize (preShape (m := 1) (n := 2) sampleShape) (preIndex (m := 1) (n := 2) wrongIndex))).val = 1 := by decide
example : (linearize sampleShape wrongIndex).val ≠
    (join (linearize (tailShape (m := 1) (n := 2) sampleShape) (tailIndex (m := 1) (n := 2) wrongIndex))
      (linearize (preShape (m := 1) (n := 2) sampleShape) (preIndex (m := 1) (n := 2) wrongIndex))).val := by decide
