module
public import ProjectionProof
public section
set_option autoImplicit false
namespace RevisedBenchmark.PadProjection
open TensorRewrite.Pilot TensorRewrite.PaperComparison.SignedPad
private def src : Shape 3 := fun _ => 2
private def dst : Shape 3 := fun d => if d = 1 then 2 else 3
private def cfg : Params src dst :=
  ⟨fun d => if d = 0 then 1 else 0, fun _ => 0, fun d => if d = 2 then 1 else 0,
   by decide +revert⟩
private def j (hole : Bool) : Index dst := Fin.cases ⟨1, by decide⟩
  (Fin.cases ⟨0, by decide⟩ (fun _ => ⟨if hole then 1 else 2, by
    change _ < _
    split <;> decide +revert⟩))
private def input (i : Fin 2) := 7 + i.val
example : retained cfg = [0,2] := by decide
example : (slot cfg 2 (by decide)).val = 1 := by decide
example : tensor cfg 99 (fun i => input (i 2)) (j false) = 8 := by decide
example : tensor cfg 99 (fun i => input (i 2)) (j true) = 99 := by decide
/-- Reading the first retained slot instead gives 7 on this non-fill output. -/
example : tensor (smaller cfg) 99 (fun i => input (i ⟨0, by decide⟩))
    (fun k => j false (axis cfg k)) = 7 := by decide
example : Goal := correct
end RevisedBenchmark.PadProjection
