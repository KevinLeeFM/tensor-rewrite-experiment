module

public import TensorRewrite.Theory.PadBroadcast

/-! Derive fused pointwise/covering geometry from independent Pad and outer window attributes. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PadBroadcast

/-- Signed edge cancellation yields a pointwise fused axis, including empty original input. -/
theorem kept_pointwise (axis : KeptAxis) :
    ConvolutionPointwise.IsPointwiseAxis (PadWindow.fusedAxis axis.padding axis.window) := by
  refine ⟨axis.unitKernel, axis.unitStride, ?_, ?_, ?_⟩
  · change axis.padding.spacing * axis.window.baseDilation = 1
    rw [axis.unitSpacing, axis.unitBase]
  · change PadWindow.fusedLow axis.padding axis.window = 0
    simp [PadWindow.fusedLow, axis.unitBase, axis.cancelLow]
  · change PadWindow.fusedHigh axis.padding axis.window = 0
    rw [PadWindow.fused_high_unit_base _ _ axis.unitBase, axis.cancelHigh]
    omega

/-- The derived singleton Broadcast axis is the actual fused axis, not a postulated sampler. -/
theorem expansion_axis (expansion : Expansion) :
    expansion.broadcast.axis = PadWindow.fusedAxis expansion.padding expansion.window := by
  cases expansion with
  | mk padding window singleton unit =>
    cases padding
    cases window
    dsimp only at singleton unit
    simp_all [Expansion.broadcast, BroadcastWindow.Expansion.axis, Expansion.offset,
      PadWindow.fusedAxis, PadWindow.fusedLow]

/-- Actual outer output extent equals the derived terminal Broadcast extent. -/
theorem expansion_output_extent (expansion : Expansion) :
    (PadWindow.outerAxis expansion.padding expansion.window).outputExtent =
      expansion.broadcast.axis.outputExtent := by
  rw [expansion_axis]
  exact PadWindow.fused_output_extent _ _

/-- Raw first/last occupied-offset inequalities imply the terminal singleton coverage contract. -/
theorem expansion_covers (expansion : Expansion) (covers : expansion.Covers) :
    expansion.broadcast.Covers := by
  unfold Expansion.Covers at covers
  unfold BroadcastWindow.Expansion.Covers
  rw [← expansion_output_extent]
  exact covers

end TensorRewrite.Theory.PadBroadcast
