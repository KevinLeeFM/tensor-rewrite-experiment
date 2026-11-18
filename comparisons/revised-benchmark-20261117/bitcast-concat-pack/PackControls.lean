module
import PackProof
set_option autoImplicit false
open RevisedBenchmark.BitcastConcat
open TensorRewrite.Theory.BitPacking

example : Goal := verified
#print axioms RevisedBenchmark.BitcastConcat.verified

private def noAxes : Coords [] := fun i => Fin.elim0 i
private def input (n base : Nat) : Block [] [2] (BitVec 16) :=
  ⟨n, fun _ i s => BitVec.ofNat 16 (base + i.val * 2 + (s 0).val)⟩
private def side : Coords [2] := fun i => ⟨1, by revert i; decide⟩
private def xs := [input 2 258, input 0 99, input 1 4660]
private def bytes (o : Order) := line (xs.map (change (split 2 8 o))) noAxes side

example : shape xs = [3, 2] := by decide
example : line xs noAxes side = [259,261,4661] := by decide
example : (bytes .leastFirst).map (fun b => (b 0, b 1)) = [(3,1),(5,1),(53,18)] := by decide
example : (bytes .mostFirst).map (fun b => (b 0, b 1)) = [(1,3),(1,5),(18,53)] := by decide
example : (bytes .leastFirst).map (pack 2 8 .leastFirst) = line xs noAxes side := by decide
example : (bytes .leastFirst).map (pack 2 8 .mostFirst) ≠ line xs noAxes side := by decide
example : (bytes .leastFirst).map (pack 2 8 .leastFirst) ≠ line xs.reverse noAxes side := by decide
example : shape [input 0 123, input 0 0] = [0, 2] := by decide
example : line [input 0 123, input 0 0] noAxes side = [] := by decide

private def pair (a b : Nat) : Words 2 8 := fun i => BitVec.ofNat 8 (if i = 0 then a else b)
private def pairs : Block [] [] (Words 2 8) :=
  ⟨2, fun _ i _ => if i = 0 then pair 255 0 else pair 1 128⟩
example : (line [change (pack 2 8 .leastFirst) pairs] noAxes noAxes) = [255,32769] := by decide
example : ((line [change (pack 2 8 .leastFirst) pairs] noAxes noAxes).map
    (split 2 8 .leastFirst)).map (fun b => b 1) = [0,128] := by decide
