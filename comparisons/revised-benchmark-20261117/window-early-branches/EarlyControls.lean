import EarlyProof
set_option autoImplicit false
namespace RevisedBenchmark.WindowEarly.Controls

-- Empty input, live three outputs from two-sided padding and a two-tap kernel.
private def a : Axis := {base := 0, widthM1 := 1, low := 2, high := 2}
example : extent a = 3 := by decide
private def mid : Coord [extent a] := .cons ⟨1,by decide⟩ .nil
example : (reads [a] mid).length = 0 := by decide
-- Reducer deliberately fails the identity law; no invocation occurs here.
example : window [a] (fun (s v : Nat) => s+v+1) 7 (fun _ => 99) mid = 7 := by decide
example : window [a] (fun (s v : Nat × Bool) => (s.1+1,!v.2)) (7,true)
    (fun _ => (99,false)) mid = (7,true) := by decide

private def wide : Axis := {base := 1,widthM1 := 1}
example : extent wide = 0 := by decide

-- Dual-number multiplication couples components while preserving (1,0) as left identity.
private def coupled (s v : Nat × Nat) := (s.1*v.1,s.1*v.2+s.2*v.1)
example (v : Nat × Nat) : coupled (1,0) v = v := by cases v; simp [coupled]
example : window [] coupled (1,0) (fun _ => (2,5)) .nil = (2,5) := by decide
example : coupled (3,4) (2,5) = (6,23) := by decide
example : window [] Nat.add 1 (fun _ => 9) .nil ≠ 9 := by decide

-- Signed padding, stride and dilation select nonconsecutive input coordinates.
private def b : Axis := {base := 5,widthM1 := 2,strideM1 := 1,winDilM1 := 1,low := 2,high := 2}
private def output : Coord [extent b] := .cons ⟨1,by decide⟩ .nil
private def cells : Coord [5] → Nat | .cons i .nil => i.val+1
private def appendDigit (s v : One Nat) := One.mk (10*s.value+v.value)
example : window [b] appendDigit ⟨0⟩ (fun p => ⟨cells p⟩) output = ⟨135⟩ := by decide
example : window [b] (fun s v => (appendDigit ⟨s⟩ ⟨v⟩).value) 0 cells output = 135 := by decide
#check (empty : EmptyGoal)
#check (scalar : ScalarGoal)
#check (singleton : SingletonGoal)
end RevisedBenchmark.WindowEarly.Controls
