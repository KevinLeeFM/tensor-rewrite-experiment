module

public import TensorRewrite.Theory.PadBroadcastProof

/-! Counterexamples to omitting actual Pad fill, converted fill or retained-axis spacing. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PadBroadcast

open Pilot

/-- A raw singleton Pad with one edge element on each side and a covering full window. -/
def coveredExpansion : Expansion where
  padding := ⟨1, 1, 1, 1, by decide⟩
  window := ⟨0, 3, 1, 1, 1, 0, 0, false, by decide, by decide, by decide⟩
  singleton := rfl
  unitKernelDilation := rfl

/-- An admitted rank-one composition used for the fill counterexamples. -/
def coveredPlan : Plan := .expand coveredExpansion (by decide) .scalar

/-- A nonneutral explicit Pad fill survives the fold even under admitted singleton coverage. -/
theorem unequal_fill_refuted :
    ReductionWindow.reduce (PadWindow.outerWindow (padPlan coveredPlan)) (· + ·) 0 0
      (PadWindow.pad (padPlan coveredPlan) 2 (Tensor.constant (5 : Nat)))
      (fun _ => ⟨0, by decide +revert⟩) = 9 ∧
    sequence coveredPlan (Tensor.constant (5 : Nat)) (fun _ => ⟨0, by decide +revert⟩) = 5 := by
  constructor
  · decide
  · have graph := congrFun (reduce_sequence coveredPlan (· + ·) 0 (by intro value; omega)
      (by intro value; omega) (Tensor.constant (5 : Nat))) (fun _ => ⟨0, by decide +revert⟩)
    exact graph.symm.trans (by decide)

/-- Losing the converted fill changes the observed result from eight to six. -/
theorem converted_fill_refuted :
    ReductionWindow.reduce (PadWindow.outerWindow (padPlan coveredPlan)) (· + ·) 0 0
      (Tensor.map (fun value : Nat => value + 1)
        (PadWindow.pad (padPlan coveredPlan) 0 (Tensor.constant (5 : Nat))))
      (fun _ => ⟨0, by decide +revert⟩) = 8 ∧
    Tensor.map (fun value : Nat => value + 1) (sequence coveredPlan (Tensor.constant 5))
      (fun _ => ⟨0, by decide +revert⟩) = 6 := by
  constructor
  · decide
  · change sequence coveredPlan (Tensor.constant 5) _ + 1 = 6
    rw [unequal_fill_refuted.2]

/-- Canceling edge Pad alone leaves an interior hole and does not preserve a retained extent. -/
theorem retained_spacing_refuted :
    (PadWindow.fusedAxis (show PadWindow.PaddingAxis from ⟨2, 1, 1, 2, by decide⟩)
      (show Convolution.Axis from
        ⟨0, 1, 1, 1, 1, -1, -1, false, by decide, by decide, by decide⟩)).outputExtent = 3 ∧
    (show PadWindow.PaddingAxis from ⟨2, 1, 1, 2, by decide⟩).inputExtent = 2 := by
  decide

end TensorRewrite.Theory.PadBroadcast
