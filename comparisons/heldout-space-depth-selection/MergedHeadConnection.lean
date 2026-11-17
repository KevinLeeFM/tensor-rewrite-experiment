module
public import RecursiveShapeSplit
public import WorkerIndexJoin
/-! Split two actual packed tails at the distinct original/replacement head ranks. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.MergedHeadConnection
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.FiniteProduct
  Heldout.RecursiveShapeSplit Heldout.WorkerIndexJoin

/-- Equal whole packed positions, with equal head and suffix cardinalities,
force the one-axis head to equal the packed two-axis head. -/
theorem merged_head_of_tail_packing {k : Nat}
    (left : Shape (k + 2)) (right : Shape (k + 1))
    (li : Index left) (ri : Index right)
    (headCount : elementCount (preShape (m := 2) (n := k) left) =
      elementCount (preShape (m := 1) (n := k) right))
    (suffixCount : elementCount (tailShape (m := 2) (n := k) left) =
      elementCount (tailShape (m := 1) (n := k) right))
    (packed : (linearize left li).val = (linearize right ri).val) :
    (preIndex (m := 1) (n := k) ri 0).val =
      (preIndex (m := 2) (n := k) li 0).val *
        (preShape (m := 2) (n := k) left 1) +
      (preIndex (m := 2) (n := k) li 1).val := by
  have packedSplit :
      (join (linearize (preShape (m := 2) (n := k) left)
          (preIndex (m := 2) (n := k) li))
        (linearize (tailShape (m := 2) (n := k) left)
          (tailIndex (m := 2) (n := k) li))).val =
      (join (linearize (preShape (m := 1) (n := k) right)
          (preIndex (m := 1) (n := k) ri))
        (linearize (tailShape (m := 1) (n := k) right)
          (tailIndex (m := 1) (n := k) ri))).val := by
    rw [← full_linearize_split li, ← full_linearize_split ri]
    exact packed
  have components := packed_component_values headCount suffixCount
    (linearize (preShape (m := 2) (n := k) left) (preIndex (m := 2) (n := k) li))
    (linearize (preShape (m := 1) (n := k) right) (preIndex (m := 1) (n := k) ri))
    (linearize (tailShape (m := 2) (n := k) left) (tailIndex (m := 2) (n := k) li))
    (linearize (tailShape (m := 1) (n := k) right) (tailIndex (m := 1) (n := k) ri)) packedSplit
  have headEq := components.1
  simp [preShape, preIndex, linearize, elementCount, FiniteProduct.join] at headEq ⊢
  exact headEq.symm

#print axioms merged_head_of_tail_packing
end Heldout.MergedHeadConnection
