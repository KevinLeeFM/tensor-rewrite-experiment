import GatherHoistProof
set_option autoImplicit false
namespace RevisedBenchmark.GatherHoist
def batch : Axis := ⟨2,1,0,1⟩
def full : Axis := ⟨3,-1,1,0⟩
local instance : NeZero (extent batch).toNat := ⟨by decide⟩
local instance : NeZero (extent full).toNat := ⟨by decide⟩
def x (i : Fin 2) (t : Fin 3) (k : Fin 5) : Nat := 100*i.val + 10*t.val + k.val
def s (i : Fin 2) (_ : Unit) : Int := if i.val = 0 then -8 else 20
def obs (bi : Fin (extent batch).toNat) (fi : Fin (extent full).toNat) : Nat :=
  padded batch full 999 x bi fi (atStart (by decide : 2 ≤ 5) (paddedStart batch 13 s bi ()) 1)
example : obs 1 0 = 11 ∧ obs 3 0 = 114 := by decide
example : obs 0 0 = 999 ∧ obs 2 1 = 999 ∧ obs 1 2 = 999 := by decide
example : padded batch full 999 x 3 0 (atStart (by decide : 2 ≤ 5) (s 0 ()) 1) = 111 := by decide
example : paddedStart batch 13 s 2 () = 13 := by decide
example : (extent (⟨0,0,0,2⟩ : Axis)).toNat = 0 := by decide
example : Case := verified
end RevisedBenchmark.GatherHoist
