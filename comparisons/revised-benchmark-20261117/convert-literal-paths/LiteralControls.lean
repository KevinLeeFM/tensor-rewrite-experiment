import LiteralProof
open RevisedBenchmark.LiteralConvert

private def input : ArrayValue [2] (BitVec 16) := fun i => if i.val = 0 then 257 else 511
private def narrow (v : ArrayValue [2] (BitVec 16)) : Option (ArrayValue [2] (BitVec 8)) :=
  some fun i => (v i).truncate 8
example : ((foldConstant narrow input).bind (eval narrow)).map (fun v => (v ⟨0, by decide⟩, v ⟨1, by decide⟩)) =
    some (1, 255) := by decide
example : ((foldConstant narrow input).bind (eval narrow)).map (fun v => v ⟨0, by decide⟩) ≠
    some 255 := by decide
example : (foldConstant (fun _ : Nat => (none : Option Nat)) 7).isNone := by decide
example : (eval (fun v => some (cloneArray v)) (.convert input)).map (fun v => v ⟨1, by decide⟩) =
    some 511 := by decide
example (v : ArrayValue [0, 3] Nat) : cloneArray v = v := rfl
