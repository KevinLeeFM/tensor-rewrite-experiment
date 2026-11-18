import DropProof
set_option autoImplicit false
namespace RevisedBenchmark.DotDropUnit

example : Case := verified
#print axioms verified

private def first (xs : Coord) : Int := (xs.headD 0 : Nat)
private def a : Operand := fun b x h => 10 * first b + first x + first h + 1
private def z : Operand := fun _ y h => first y + first h + 2

-- Direct return: only the contracting coordinate of extent one disappears.
example : replacement [] [2] [] [2,1] a z = ([2], [8,13]) := by decide
-- Restored unit dimensions in batch and each free frame, including rank-zero dot.
example : replacement [1] [2,1] [1] [2,1] a z = ([1,2,1,1], [8,13]) := by decide
example : replacement [] [] [] [1] a z = ([], [2]) := by decide
-- A zero contracting extent produces zeros; a zero free extent gives no output.
example : replacement [] [2] [] [1,0] a z = ([2], [0,0]) := by decide
example : replacement [] [0,1] [] [3] a z = ([0,1], []) := by decide
-- Dropping a free unit without restoring the old result shape is observable.
example : replacement [1] [2,1] [1] [2,1] a z ≠ ([2], [8,13]) := by decide
-- Wrong reinsertion of a singleton at the other end changes a read.
example : expand [1,3] [2] ≠ [2,0] := by decide
-- Nonsorted dimension-number lists, with a unit in the middle and distinct maps.
private def leftIds := [2,1,0]
private def rightIds := [0,1,2]
example : ((leftIds.filterMap (remap [3,1,2])).zip
    (rightIds.filterMap (remap [2,1,3]))) = [(1,0),(0,1)] := by decide
example : ((leftIds.filterMap (remap [3,1,2])).zip
    (rightIds.filterMap (remap [2,1,3]))) ≠ [(0,0),(1,1)] := by decide
end RevisedBenchmark.DotDropUnit
