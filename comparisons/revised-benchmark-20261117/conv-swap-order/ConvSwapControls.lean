import ConvSwapProof
set_option autoImplicit false
namespace RevisedBenchmark.ConvSwapOrder
example : after = ⟨4,3,-1,0,true⟩ ∧ extent before = 1 ∧ extent after = 1 ∧
    before.width > after.width := by decide
example : (pairs before ⟨0,by decide⟩).map (fun (i,j) => (i.val,j.val)) =
    [(0,0),(1,1),(2,2)] := by decide
example : (pairs after ⟨0,by decide⟩).map (fun (i,j) => (i.val,j.val)) =
    [(1,2),(2,1),(3,0)] := by decide
example : (pairs after ⟨0,by decide⟩).map (fun (i,j) => (j.val,(mirror i).val)) =
    [(2,2),(1,1),(0,0)] := by decide
example : terms before ⟨0,by decide⟩ sample filter = [1,1,16777216] ∧
    terms after ⟨0,by decide⟩ (fun i => filter (mirror i)) sample = [16777216,1,1] := by decide
example : (terms before ⟨0,by decide⟩ sample filter).sum =
    (terms after ⟨0,by decide⟩ (fun i => filter (mirror i)) sample).sum := by decide
example : original (fun _ => 2) filter = 6 ∧ rewritten (fun _ => 2) filter = 6 := by decide
-- Omitting the actual Reverse includes the sentinel weight.
example : sum32 (terms after ⟨0,by decide⟩ filter sample) ≠ rewritten sample filter := by decide
#check (refuted : ¬ StrictCase)
end RevisedBenchmark.ConvSwapOrder
