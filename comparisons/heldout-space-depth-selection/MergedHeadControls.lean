module
import MergedHeadConnection
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex Heldout.MergedHeadConnection
set_option autoImplicit false
namespace MergedHeadControls
def leftShape : Shape 3 := fun i => if i.val = 0 then 2 else if i.val = 1 then 3 else 4
def rightShape : Shape 2 := fun i => if i.val = 0 then 6 else 4
def leftIndex : Index leftShape := fun i => ⟨if i.val = 0 then 1 else if i.val = 1 then 2 else 3,
  (show ∀ i : Fin 3, (if i.val = 0 then 1 else if i.val = 1 then 2 else 3) < leftShape i by decide) i⟩
def rightIndex : Index rightShape := fun i => ⟨if i.val = 0 then 5 else 3,
  (show ∀ i : Fin 2, (if i.val = 0 then 5 else 3) < rightShape i by decide) i⟩
example : (linearize leftShape leftIndex).val = (linearize rightShape rightIndex).val := by decide
example := merged_head_of_tail_packing leftShape rightShape leftIndex rightIndex (by decide) (by decide) (by decide)
example : (linearize leftShape leftIndex).val ≠ (linearize rightShape (fun i => ⟨if i.val = 0 then 4 else 3,
  (show ∀ i : Fin 2, (if i.val = 0 then 4 else 3) < rightShape i by decide) i⟩)).val := by decide
example : ¬ Nonempty (Index (fun _ : Fin 1 => 0)) := by intro ⟨i⟩; exact Fin.elim0 (i 0)
end MergedHeadControls
