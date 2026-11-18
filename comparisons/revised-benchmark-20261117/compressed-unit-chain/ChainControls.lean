import GuardProof
namespace CompressedChain
open TensorRewrite.Pilot
def revP (n : Nat) : AxisPermutation n := ⟨Fin.rev, Fin.rev, Fin.rev_rev, Fin.rev_rev⟩
def swap2 := Step.plainT (revP 2)
def swap3 := Step.unitT (n:=2) 1 1 (revP 3) (by decide)
def cancel : Chain 2 .plain .plain := .snoc (.snoc (.snoc (.snoc (.start _) swap2)
    (.edit .plain (.unit 1))) swap3) (.edit (.unit 1) .plain)
example : ∀ i, total cancel i = i := by decide
example : eff swap2 0 ≠ 0 ∧ eff swap3 0 ≠ 0 := by decide
def y2 : Digits (Frame.plain (n:=2)) := fun i => if i.val = 0 then 1 else 2
example : back cancel y2 (0 : Fin 2) = 1 ∧ back cancel y2 (1 : Fin 2) = 2 := by decide
-- A 3-cycle is not its own inverse; composition with reversal does not commute.
def cycle3 : AxisPermutation 3 := ⟨fun i => ⟨(i.val+1)%3, by omega⟩,
  fun i => ⟨(i.val+2)%3, by omega⟩, by decide, by decide⟩
def orderTest : Chain 3 .plain .plain := .snoc (.snoc (.start _) (.plainT cycle3)) (.plainT (revP 3))
example : total orderTest 0 = 0 ∧ (revP 3).outputToInput (cycle3.outputToInput 0) = 1 := by decide
-- Nontrivial singleton-location change under transpose; visible labels [0,1].
def rotate := Step.unitT (n:=2) 0 2 cycle3 (by decide)
example : eff rotate 0 = 0 ∧ eff rotate 1 = 1 := by decide
def unitMove : Chain 2 (.unit 0) (.unit 2) := .snoc (.start _) rotate
def widths (i : Fin 2) : Nat := if i.val=0 then 2 else 3
def y3 : Digits (Frame.unit (n:=2) 2) := fun i => if i.val=0 then 1 else 0
example : validUnit (.unit 2) y3 := by rfl
example : address (.unit 0) 0 (revP 2) widths (back unitMove y3) = 1 ∧
    address (.unit 2) 2 (revP 2) widths y3 = 1 ∧
    address (.unit 2) 2 (AxisPermutation.identity 2) widths y3 = 3 := by decide
example : ordinal (pairs (.unit 2) widths y3) 0 = 3 := by decide
example : ordinal (pairs (.unit (n:=0) 0) (fun i => Fin.elim0 i) (fun _ => 0)) 0 = 0 := by decide
#check (step_verified : StepGate)
#check (edit_verified : EditGate)
#check (chain_verified : ChainGate)
#check (raw_verified : RawGate)
#check (guard_verified : GuardGate)
#check (bounded_verified : BoundedAddressGate)
end CompressedChain
