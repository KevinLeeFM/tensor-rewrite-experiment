module

public import TensorRewrite.Theory.BroadcastWindowTarget

/-! Every admitted output has exactly one live contribution, derived from axis geometry. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BroadcastWindow

open Pilot

/-- The unique full kernel coordinate that samples the represented original input. -/
def liveKernel : (plan : Plan) → Index (windowPlan plan).outputShape →
    Index (windowPlan plan).kernelShape
  | .scalar, _ => fun axis => Fin.elim0 axis
  | .keep axis pointwise tail, output =>
    Fin.cases ⟨0, by change 0 < axis.kernelExtent; rw [pointwise.unitKernel]; decide⟩
      (liveKernel tail (fun axis => output axis.succ))
  | .expand expansion covers tail, output =>
    Fin.cases (expansionKernel expansion covers (output ⟨0, Nat.zero_lt_succ _⟩))
      (liveKernel tail (fun axis => output axis.succ))

/-- Every axis at the selected kernel coordinate returns its derived original coordinate. -/
theorem live_axis_sample (plan : Plan) (output : Index (windowPlan plan).outputShape)
    (axis : Fin plan.rank) :
    ((windowPlan plan).window axis).inputIndex? (output axis).val (liveKernel plan output axis) =
      some (sourceIndex plan output axis) := by
  induction plan with
  | scalar => exact Fin.elim0 axis
  | keep window pointwise tail ih =>
    refine Fin.cases ?_ (fun axis => ?_) axis
    · exact ConvolutionPointwise.axis_inputIndex_eq window pointwise _ _
    · exact ih (fun axis => output axis.succ) axis
  | expand expansion covers tail ih =>
    refine Fin.cases (expansion_sample expansion covers _) (fun axis => ?_) axis
    exact ih (fun axis => output axis.succ) axis

/-- The actual multidimensional sampler succeeds at the unique live kernel coordinate. -/
theorem sample_live (plan : Plan) (output : Index (windowPlan plan).outputShape) :
    ReductionWindow.sample? (windowPlan plan) output (liveKernel plan output) =
      some (sourceIndex plan output) := by
  apply (LatticeIndex.assemble_eq_some_iff _ _).mpr
  intro axis
  exact live_axis_sample plan output axis

/-- Any successful axis sample determines that axis's unique live kernel coordinate. -/
theorem axis_kernel_unique (plan : Plan) (output : Index (windowPlan plan).outputShape)
    (kernel : Index (windowPlan plan).kernelShape) (axis : Fin plan.rank)
    (input : Fin ((windowPlan plan).inputShape axis))
    (sample : ((windowPlan plan).window axis).inputIndex?
      (output axis).val (kernel axis) = some input) :
    kernel axis = liveKernel plan output axis := by
  induction plan with
  | scalar => exact Fin.elim0 axis
  | keep window pointwise tail ih =>
    revert input
    refine Fin.cases (fun input sample => ?_) (fun axis input sample => ?_) axis
    · apply Fin.ext
      have bound := (kernel ⟨0, Nat.zero_lt_succ _⟩).isLt
      change (kernel ⟨0, Nat.zero_lt_succ _⟩).val < window.kernelExtent at bound
      have unit := pointwise.unitKernel
      change (kernel ⟨0, Nat.zero_lt_succ _⟩).val = 0
      omega
    · exact ih (fun axis => output axis.succ) (fun axis => kernel axis.succ) axis input sample
  | expand expansion covers tail ih =>
    revert input
    refine Fin.cases (fun input sample => ?_) (fun axis input sample => ?_) axis
    · exact expansion_unique expansion covers _ _ input sample
    · exact ih (fun axis => output axis.succ) (fun axis => kernel axis.succ) axis input sample

/-- The complete sampler is present precisely once; every other kernel position is padding. -/
theorem sample_if (plan : Plan) (output : Index (windowPlan plan).outputShape)
    (kernel : Index (windowPlan plan).kernelShape) :
    ReductionWindow.sample? (windowPlan plan) output kernel =
      if kernel = liveKernel plan output then some (sourceIndex plan output) else none := by
  classical
  by_cases same : kernel = liveKernel plan output
  · simp only [same, sample_live, ite_true]
  · rw [ite_eq_right same]
    cases sampled : ReductionWindow.sample? (windowPlan plan) output kernel with
    | none => rfl
    | some input =>
      have every := (LatticeIndex.assemble_eq_some_iff _ input).mp sampled
      exfalso
      apply same
      funext axis
      exact axis_kernel_unique plan output kernel axis (input axis) (every axis)

end TensorRewrite.Theory.BroadcastWindow
