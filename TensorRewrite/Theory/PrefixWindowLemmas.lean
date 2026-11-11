module

public import TensorRewrite.Theory.PrefixWindowTarget
public import TensorRewrite.Theory.OrderedCoordinates
public import TensorRewrite.Theory.FullSpanWindowLemmas
public import TensorRewrite.Theory.ReductionWindowLemmas
public import TensorRewrite.Theory.LatticeIndex

/-! Scan geometry and complete ordered kernel enumeration, including empty scan extents. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PrefixWindow

open Pilot

/-- A shape of unit extents enumerates one coordinate, in its unique possible position. -/
theorem unit_enumerate_map {rank : Nat} {α : Type} (shape : Shape rank)
    (unit : ∀ axis, shape axis = 1) (value : Index shape → α) (index : Index shape) :
    (OrderedCoordinates.enumerate shape).map value = [value index] := by
  unfold OrderedCoordinates.enumerate
  rw [List.map_map]
  have count := ConvolutionPointwise.elementCount_unit shape unit
  trans [value (LinearIndex.delinearize shape ⟨0, by omega⟩)]
  · exact ConvolutionOrdered.map_finRange_singleton count _
  · congr 1
    apply congrArg value
    funext axis
    apply Fin.ext
    have first := (LinearIndex.delinearize shape ⟨0, by omega⟩ axis).isLt
    have second := (index axis).isLt
    have extent := unit axis
    omega

/-- Arbitrary-rank kernel enumeration is exactly the scan range in increasing order. -/
theorem kernel_enumerate {rank : Nat} {α : Type} (plan : Plan rank)
    (value : Index (windowPlan plan).kernelShape → α) :
    (OrderedCoordinates.enumerate (windowPlan plan).kernelShape).map value =
      (List.finRange (scanExtent plan)).map fun position => value (kernelIndex plan position) := by
  induction plan with
  | scan extent tail stride =>
    trans (List.finRange extent).flatMap fun head =>
      (OrderedCoordinates.enumerate
        (fun axis => (windowPlan (.scan extent tail stride)).kernelShape axis.succ)).map fun rest =>
          value (Fin.cases head rest)
    · exact OrderedCoordinates.enumerate_uncons_map _ _
    · have blocks (head : Fin extent) :
          (OrderedCoordinates.enumerate
            (fun axis => (windowPlan (.scan extent tail stride)).kernelShape axis.succ)).map
            (fun rest => value (Fin.cases head rest)) =
            [value (kernelIndex (.scan extent tail stride) head)] :=
        unit_enumerate_map _ (fun _ => rfl) _ _
      simp only [blocks, ← List.map_eq_flatMap]
      rfl
  | keep extent stride tail ih =>
    trans (List.finRange 1).flatMap fun head =>
      (OrderedCoordinates.enumerate (windowPlan tail).kernelShape).map fun rest =>
        value (Fin.cases head rest)
    · exact OrderedCoordinates.enumerate_uncons_map _ _
    · simp only [List.finRange_succ, List.finRange_zero, List.map_nil,
        List.flatMap_cons, List.flatMap_nil, List.append_nil]
      exact ih (fun rest => value (Fin.cases ⟨0, by change 0 < 1; decide⟩ rest))

/-- Actual ordered window values may be indexed directly by the scan coordinate. -/
theorem values_scan_range {rank : Nat} {α : Type} (plan : Plan rank) (padding : α)
    (input : Tensor (windowPlan plan).inputShape α)
    (output : Index (windowPlan plan).outputShape) :
    ReductionWindow.values (windowPlan plan) padding input output =
      (List.finRange (scanExtent plan)).map fun position =>
        ReductionWindow.contribution (windowPlan plan) padding input output
          (kernelIndex plan position) := by
  have ordered := kernel_enumerate plan
    (ReductionWindow.contribution (windowPlan plan) padding input output)
  simpa only [OrderedCoordinates.enumerate, List.map_map, Function.comp_def,
    ReductionWindow.values] using ordered

end TensorRewrite.Theory.PrefixWindow
