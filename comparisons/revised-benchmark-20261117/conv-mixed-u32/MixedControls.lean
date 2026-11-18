import MixedProof
open RevisedBenchmark.ConvMixedU32
#check (verified : Goal)
example : 255*255 < 4294967296 := by decide
example : 2*4294967295 % 4294967296 = 4294967294 := by decide
-- An overflowing product can still agree with a clamped result.
example : 7*1227133513 > 4294967295 ∧ 7*1227133513 % 4294967296 = 4294967295 := by decide
namespace RevisedBenchmark.ConvMixedU32.Controls
open ConvPointAxes
private def physical : Order where
  slot | .batch => 0 | .feature => 1 | .space => 2
  role p := if p=0 then .batch else if p=1 then .feature else .space
  slot_role := by decide
  role_slot := by intro a; cases a <;> rfl
private def sizes : Sizes := ⟨1,2,1,1⟩
private def coord : Coord := place physical 0 1 0
private def result (a b : Storage) (v : Fin (limit a)) (z : Fin (limit b)) :=
  (evaluated sizes physical physical physical coord (fun _ => v) (fun _ => z),
   emitted sizes physical physical physical coord (fun _ => v) (fun _ => z))
example : Fits (outShape sizes physical) coord := by unfold Fits; decide
example : result .byte .byte ⟨255,by decide⟩ ⟨255,by decide⟩ = (65025,65025) := by decide
example : result .byte .word ⟨2,by decide⟩ ⟨4294967295,by decide⟩ =
    (4294967295,4294967294) := by decide
example : result .word .byte ⟨4294967295,by decide⟩ ⟨2,by decide⟩ =
    (4294967295,4294967294) := by decide
example : result .byte .word ⟨7,by decide⟩ ⟨1227133513,by decide⟩ =
    (4294967295,4294967295) := by decide
end RevisedBenchmark.ConvMixedU32.Controls
