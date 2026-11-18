import SliceDotProof
set_option autoImplicit false
namespace RevisedBenchmark.SliceDot.Controls
open RevisedBenchmark.SliceDot
private def left : List (Axis 2 1 2) := [.batch 1,.contract 1,.free 0,.batch 0,.contract 0]
private def right : List (Axis 2 1 2) := [.contract 0,.batch 0,.contract 1,.batch 1,.free 0]
private def slices : Nat → Slice
  | 0 => ⟨1,7,2⟩ | 1 => ⟨2,6,1⟩ | 2 => ⟨1,8,3⟩ | _ => ⟨0,9,2⟩
private def dims : Nat → Nat | 0 => 8 | 1 => 7 | 2 => 8 | _ => 9
private def ks (i : Fin 2) := if i.val = 0 then 2 else 3
private def q (j : Nat) := if j = 0 then 0 else 1
private def val (p : List Nat) : Int := p.foldl (fun acc n => 10*acc + Int.ofNat n) 0

example : Lawful left ∧ Lawful right := by unfold Lawful; decide
example : ∀ j : Fin 4, (slices j).start ≤ (slices j).limit ∧
    (slices j).limit ≤ dims j ∧ 0 < (slices j).stride ∧ q j < width (slices j) := by decide
example : left.map (slot 2) = [some 1, none, some 2, some 0, none] ∧
    right.map (slot 3) = [none, some 0, none, some 1, some 3] := by decide
example : projectedShape left 2 ks slices = [4,3,3,3,2] ∧
    projectedShape right 3 ks slices = [2,3,3,4,5] := by decide
private def before := dot (List.ofFn ks) (originalOperand left 2 slices q val)
    (originalOperand right 3 slices q val)
private def after (rightOffset : Nat) := dot (List.ofFn ks)
    (replacementOperand left 2 dims ks slices q val)
    (replacementOperand right rightOffset dims ks slices q val)
example : before = 1156070116 ∧ after 3 = before := by decide
/-- Using the lhs-free slot for the rhs changes the full contraction. -/
example : after 2 = 1156447042 ∧ after 2 ≠ before := by decide
/-- Omitting a nonunit free-axis stride fetches a different physical coordinate. -/
example : atCoord (project 2 ks slices (Axis.free (b:=2) (f:=1) 0)) (q 2) ≠
    (slices 2).start + q 2 := by decide
example : dot [2,0,3] (fun _ => 1) (fun _ => 2) = 0 ∧
    dot [] (fun _ => 2) (fun _ => 3) = 6 := by decide
/-- An unchanged operand takes the unsliced branch. -/
example : replacementOperand left 2 dims ks (fun j => whole (dims j)) q val [1,2] =
    val (left.map (readAt 2 q [1,2])) := by decide
#check (verified : Case)
#print axioms verified
end RevisedBenchmark.SliceDot.Controls
