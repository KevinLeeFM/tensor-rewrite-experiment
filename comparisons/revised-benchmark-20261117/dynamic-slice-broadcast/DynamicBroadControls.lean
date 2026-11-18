import DynamicBroadProof
set_option autoImplicit false
namespace RevisedBenchmark.DynamicBroad
def mapped (a : Fin 2) : Fin 3 := if a.val=0 then 0 else 2
def ex : Plan 2 3 where
  input := fun i => if i.val=0 then 4 else 6
  expanded := fun i => if i.val=0 then 4 else if i.val=1 then 9 else 6
  widths := fun _ => 2
  axes := mapped
  matchExtent := by decide
  fits := by decide
def starts (i : Fin 3) : Int := if i.val=0 then -5 else if i.val=1 then 0 else 23
def label (j : TensorRewrite.Pilot.Index ex.input) := 10*(j 0).val + (j 1).val
def atOne : TensorRewrite.Pilot.Index ex.widths := fun _ => ⟨1,by decide +revert⟩
example : slice ex.fits starts (broad ex.axes ex.matchExtent label) atOne = 15 := by decide
example : slice ex.fits (fun i => if i.val=2 then starts 1 else starts i)
    (broad ex.axes ex.matchExtent label) atOne = 11 := by decide
def scalar (w : Nat) (hw : w ≤ 3) : Plan 0 1 where
  input := fun a => a.elim0
  expanded := fun _ => 3
  widths := fun _ => w
  axes := fun a => a.elim0
  matchExtent := fun a => a.elim0
  fits := fun _ => hw
example : let p := scalar 1 (by decide)
  slice p.fits (fun _ => 3) (broad p.axes p.matchExtent (fun _ => (7 : Nat)))
    (fun _ => ⟨0,by decide +revert⟩) = 7 := by decide
example (q : TensorRewrite.Pilot.Index (scalar 0 (by decide)).widths) : False :=
  Nat.not_lt_zero _ (q 0).isLt
example : Case := verified
end RevisedBenchmark.DynamicBroad
