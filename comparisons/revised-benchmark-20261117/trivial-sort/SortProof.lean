module
public import SortSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.TrivialSort
open TensorRewrite.Pilot
/-- An admitted index rules out empty dimensions. The selected entry on the
    sort axis is then the unique element of its bounded coordinate type. -/
theorem correct : Goal := by
  intro r s axis pick guard
  have onArray {α : Type} (xs : Tensor s α) : rearrange axis pick xs = xs := by
    funext j
    rcases guard with ⟨d, zero⟩ | small
    · have bound := (j d).isLt
      omega
    · apply congrArg xs
      funext d
      by_cases h : axis = d
      · subst d
        simp only
        apply Fin.ext
        have left := (pick j).isLt
        have right := (j axis).isLt
        omega
      · simp [h]
  exact ⟨fun xs => onArray xs, fun xs => funext (fun c => onArray (xs c))⟩

private def two : Shape 1 := fun _ => 2
private def input : Tensor two Nat := fun j => (j 0).val
private def flip : Index two → Fin (two 0) := fun j => ⟨1 - (j 0).val, by change _ < 2; omega⟩
private def first : Index two := fun _ => ⟨0, by change 0 < 2; decide⟩
example : rearrange 0 flip input first ≠ input first := by decide

private def rows : Shape 2 := Fin.cases 3 (fun _ => 1)
private def lastRow : Index rows := Fin.cases ⟨2, by decide⟩ (fun _ => ⟨0, by change 0 < 1; decide⟩)
example : rearrange (s := rows) 1 (fun j => j 1) (fun j => (j 0).val) lastRow = 2 := by decide
private def emptyShape : Shape 2 := Fin.cases 0 (fun _ => 4)
example : emptyShape 1 = 4 ∧ emptyShape 0 = 0 := by decide
example : ¬ Nonempty (Index emptyShape) := by
  intro ⟨j⟩
  exact (j 0).elim0
#print axioms correct
end RevisedBenchmark.TrivialSort
