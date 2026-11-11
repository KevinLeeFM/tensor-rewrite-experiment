module

public import TensorRewrite.Theory.FullSpanWindow
public import Mathlib.Data.PNat.Basic

/-! One cumulative axis at any position, with arbitrary retained axes before and after it. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PrefixWindow

open Pilot

/-- A length-n cumulative window has signed low padding n-1, including n=0. -/
def prefixAxis (extent : Nat) : Convolution.Axis :=
  { FullSpanWindow.keptAxis extent with
    kernelExtent := extent
    paddingLow := (extent : Int) - 1 }

/-- A retained axis samples at its arbitrary positive stride without padding or base holes. -/
def retainedAxis (extent : Nat) (stride : ℕ+) : Convolution.Axis :=
  { FullSpanWindow.keptAxis extent with stride := stride.val, stride_pos := stride.pos }

/-- A scan axis with arbitrary trailing shape, preceded by any number of kept axes. -/
inductive Plan : Nat → Type where
  | scan {rank : Nat} (extent : Nat) (tailShape : Shape rank) (tailStride : Fin rank → ℕ+) :
      Plan (rank + 1)
  | keep {rank : Nat} (extent : Nat) (stride : ℕ+) (tail : Plan rank) : Plan (rank + 1)

/-- Construct the actual window attributes; all non-scan axes have unit windows. -/
def windowPlan : {rank : Nat} → Plan rank → ReductionWindow.Plan rank
  | _, .scan extent tail stride =>
    ⟨Fin.cases (prefixAxis extent) (fun axis => retainedAxis (tail axis) (stride axis))⟩
  | _, .keep extent stride tail =>
    ⟨Fin.cases (retainedAxis extent stride) (windowPlan tail).window⟩

/-- Extent of the unique scan axis. -/
def scanExtent : {rank : Nat} → Plan rank → Nat
  | _, .scan extent _ _ => extent
  | _, .keep _ _ tail => scanExtent tail

/-- Project an input coordinate onto the unique scan axis. -/
def coordinate : {rank : Nat} → (plan : Plan rank) →
    Index (windowPlan plan).inputShape → Fin (scanExtent plan)
  | _, .scan _ _ _, index => index ⟨0, Nat.zero_lt_succ _⟩
  | _, .keep _ _ tail, index => coordinate tail (fun axis => index axis.succ)

/-- Replace the scan coordinate while keeping every other input coordinate fixed. -/
def replaceCoordinate : {rank : Nat} → (plan : Plan rank) →
    Index (windowPlan plan).inputShape → Fin (scanExtent plan) → Index (windowPlan plan).inputShape
  | _, .scan _ _ _, index, value => Fin.cases value (fun axis => index axis.succ)
  | _, .keep _ _ tail, index, value =>
    Fin.cases (index ⟨0, Nat.zero_lt_succ _⟩)
      (replaceCoordinate tail (fun axis => index axis.succ) value)

/-- Enumerate the scan kernel coordinate; every other kernel coordinate is zero. -/
def kernelIndex : {rank : Nat} → (plan : Plan rank) → Fin (scanExtent plan) →
    Index (windowPlan plan).kernelShape
  | _, .scan _ _ _, value => Fin.cases value (fun _ => ⟨0, by change 0 < 1; decide⟩)
  | _, .keep _ _ tail, value =>
    Fin.cases ⟨0, by change 0 < 1; decide⟩ (kernelIndex tail value)

end TensorRewrite.Theory.PrefixWindow
