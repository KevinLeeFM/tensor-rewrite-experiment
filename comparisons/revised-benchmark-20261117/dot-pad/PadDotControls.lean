import PadDotProof
set_option autoImplicit false
namespace RevisedBenchmark.PadDot
private def a : Axis := ⟨2,1,2,1⟩
private def x (i : List Nat) : Int := if i = [0] then 2 else 5
private def y (p : List Nat) : Int := Int.ofNat (p.head! + 1)

example : (extent a, limit a, sliced a) = (6,4,2) := by decide
example : ((List.range 6).map (fun j => padded [a] x [j])) = [0,2,0,5,0,0] := by decide
example : original [a] true x y = 24 ∧ replacement [a] false x y = 24 := by decide
/-- A well-typed replacement that forgets the interior padding's effect on stride. -/
example : original [a] true x y ≠
    total (grid [2]) (fun i => x i * y [a.low + i.head!]) := by decide
example : original [⟨0,2,3,7⟩] true x y = 0 ∧
    replacement [⟨0,2,3,7⟩] true x y = 0 := by decide
private def table (i : List Nat) : Int := Int.ofNat (i[0]! + 2 * i[1]! + i[2]!)
private def weight (p : List Nat) : Int := Int.ofNat (1 + p[0]! + p[1]! + p[2]!)
/-- Two moved axes separated by one retained axis; model a retained zero cell. -/
private def cropped (i : List Nat) : Int := if i[1]! = 0 then 0 else table i
private def multi := [a, ⟨2,0,0,0⟩, ⟨2,2,0,2⟩]
example : replacement multi true cropped weight = 95 ∧ original multi false cropped weight = 95 := by decide
end RevisedBenchmark.PadDot
