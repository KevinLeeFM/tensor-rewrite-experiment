module

public import TensorRewrite.Pilot.SliceShape

/-! Shape-preservation counterexamples for two source-shaped axis transformations.
These certificates concern static shape legality, not tensor element equality. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.SliceShape

/-- Legal empty slice used in the pinned-XLA replay. -/
@[expose] def emptyWitness : Axis := { start := 1, limit := 1, stride := 2 }

/-- The input witness satisfies every static bound and output-extent condition. -/
theorem empty_witness_well_formed : IsWellFormed 4 0 emptyWitness := by
  decide

/-- Redundant-stride removal produces the observed one-element bounds. -/
theorem remove_redundant_stride_witness :
    removeRedundantStride emptyWitness = { start := 1, limit := 2, stride := 1 } := by
  decide

/-- The changed bounds disagree with the retained zero-element output extent. -/
theorem remove_redundant_stride_refutes :
    ¬ IsWellFormed 4 0 (removeRedundantStride emptyWitness) := by
  decide

/-- Slice/reverse reordering produces the observed one-element bounds. -/
theorem reorder_reverse_witness :
    reorderReverse 4 emptyWitness = { start := 2, limit := 3, stride := 2 } := by
  decide

/-- The reversed-axis replacement also violates the retained output extent. -/
theorem reorder_reverse_refutes :
    ¬ IsWellFormed 4 0 (reorderReverse 4 emptyWitness) := by
  decide

/-- Redundant-stride removal cannot preserve all legal declared slice shapes. -/
theorem remove_redundant_stride_not_preserving :
    ¬ (∀ extent declared axis,
      IsWellFormed extent declared axis →
        IsWellFormed extent declared (removeRedundantStride axis)) := by
  intro preserving
  exact remove_redundant_stride_refutes (preserving 4 0 emptyWitness empty_witness_well_formed)

/-- Slice/reverse reordering cannot preserve all legal declared slice shapes. -/
theorem reorder_reverse_not_preserving :
    ¬ (∀ extent declared axis,
      IsWellFormed extent declared axis →
        IsWellFormed extent declared (reorderReverse extent axis)) := by
  intro preserving
  exact reorder_reverse_refutes (preserving 4 0 emptyWitness empty_witness_well_formed)

end TensorRewrite.Pilot.SliceShape
