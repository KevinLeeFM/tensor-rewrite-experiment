module

public import TensorRewrite.Theory.FullSpanWindow
public import TensorRewrite.Theory.ConvolutionPointwiseLemmas
public import TensorRewrite.Theory.OrderedCoordinates
public import TensorRewrite.Pilot.ReshapeLemmas

/-! Canonical full-span geometry and coordinate transports, derived from the axis plan. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.FullSpanWindow

open Pilot

/-- A kept axis has precisely its original extent. -/
theorem kept_output_extent (extent : Nat) : (keptAxis extent).outputExtent = extent :=
  ConvolutionPointwise.output_extent_eq _ ⟨rfl, rfl, rfl, rfl, rfl⟩

/-- A full-span axis has one output position, also for an empty kernel in this model. -/
theorem reduced_output_extent (extent : Nat) : (reducedAxis extent).outputExtent = 1 := by
  simp [Convolution.Axis.outputExtent, reducedAxis, keptAxis]

/-- Kept axes sample the original bounded output coordinate. -/
theorem kept_sample (extent : Nat) (output : Fin (keptAxis extent).outputExtent)
    (kernel : Fin (keptAxis extent).kernelExtent) :
    (keptAxis extent).inputIndex? output.val kernel =
      some (Fin.cast (kept_output_extent extent) output) :=
  ConvolutionPointwise.axis_inputIndex_eq _ ⟨rfl, rfl, rfl, rfl, rfl⟩ _ _

/-- Full-span axes sample their kernel coordinate without holes, reversal or padding. -/
theorem reduced_sample (extent : Nat) (output : Fin (reducedAxis extent).outputExtent)
    (kernel : Fin extent) :
    (reducedAxis extent).inputIndex? output.val kernel = some kernel := by
  have zero : output.val = 0 := by
    have bound := Nat.lt_of_lt_of_eq output.isLt (reduced_output_extent extent)
    omega
  simp [Convolution.Axis.inputIndex?, Convolution.Axis.basePosition, reducedAxis, keptAxis,
    zero, kernel.isLt]

/-- The canonical window uses exactly the original input shape. -/
theorem input_shape (plan : Reduction.Plan) : (windowPlan plan).inputShape = plan.inputShape := by
  induction plan with
  | scalar => funext axis; exact Fin.elim0 axis
  | keep extent tail ih | reduce extent tail ih =>
    funext axis
    exact Fin.cases rfl (fun axis => congrFun ih axis) axis

/-- Recovering transported coordinates is an identity on the original input. -/
theorem original_input (plan : Reduction.Plan) (index : Index plan.inputShape) :
    originalIndex plan (inputIndex plan index) = index := by
  induction plan with
  | scalar => funext axis; exact Fin.elim0 axis
  | keep extent tail ih | reduce extent tail ih =>
    funext axis
    exact Fin.cases rfl (fun axis => congrFun (ih (fun axis => index axis.succ)) axis) axis

/-- Transporting recovered coordinates is an identity on the canonical window input. -/
theorem input_original (plan : Reduction.Plan) (index : Index (windowPlan plan).inputShape) :
    inputIndex plan (originalIndex plan index) = index := by
  induction plan with
  | scalar => funext axis; exact Fin.elim0 axis
  | keep extent tail ih | reduce extent tail ih =>
    funext axis
    exact Fin.cases rfl (fun axis => congrFun (ih (fun axis => index axis.succ)) axis) axis

/-- Drop exactly the singleton output axes corresponding to reduced input axes. -/
def outputIndex : (plan : Reduction.Plan) → Index (windowPlan plan).outputShape →
    Index plan.outputShape
  | .scalar, _ => fun axis => Fin.elim0 axis
  | .keep extent tail, output =>
    Fin.cases (Fin.cast (kept_output_extent extent) (output ⟨0, Nat.zero_lt_succ _⟩))
      (outputIndex tail (fun axis => output axis.succ))
  | .reduce _ tail, output => outputIndex tail (fun axis => output axis.succ)

/-- Assemble the actual sampled input coordinate from the kept and full-span axes. -/
def sampleIndex : (plan : Reduction.Plan) → Index (windowPlan plan).outputShape →
    Index (windowPlan plan).kernelShape → Index (windowPlan plan).inputShape
  | .scalar, _, _ => fun axis => Fin.elim0 axis
  | .keep extent tail, output, kernel =>
    Fin.cases (Fin.cast (kept_output_extent extent) (output ⟨0, Nat.zero_lt_succ _⟩))
      (sampleIndex tail (fun axis => output axis.succ) (fun axis => kernel axis.succ))
  | .reduce _ tail, output, kernel =>
    Fin.cases (kernel ⟨0, Nat.zero_lt_succ _⟩)
      (sampleIndex tail (fun axis => output axis.succ) (fun axis => kernel axis.succ))

/-- Every individual axis sample is valid and equals the assembled coordinate. -/
theorem axis_sample (plan : Reduction.Plan) (output : Index (windowPlan plan).outputShape)
    (kernel : Index (windowPlan plan).kernelShape) (axis : Fin plan.inputRank) :
    ((windowPlan plan).window axis).inputIndex? (output axis).val (kernel axis) =
      some (sampleIndex plan output kernel axis) := by
  induction plan with
  | scalar => exact Fin.elim0 axis
  | keep extent tail ih =>
    refine Fin.cases (kept_sample extent _ _) (fun axis => ?_) axis
    exact ih (fun axis => output axis.succ) (fun axis => kernel axis.succ) axis
  | reduce extent tail ih =>
    refine Fin.cases (reduced_sample extent _ _) (fun axis => ?_) axis
    exact ih (fun axis => output axis.succ) (fun axis => kernel axis.succ) axis

/-- The actual bounded window sampler succeeds; the padding value is never consulted. -/
theorem sample_valid (plan : Reduction.Plan) (output : Index (windowPlan plan).outputShape)
    (kernel : Index (windowPlan plan).kernelShape) :
    ReductionWindow.sample? (windowPlan plan) output kernel =
      some (sampleIndex plan output kernel) := by
  unfold ReductionWindow.sample? Convolution.spatialInput?
  have valid : ∀ axis,
      (((windowPlan plan).window axis).inputIndex? (output axis).val (kernel axis)).isSome := by
    intro axis
    rw [axis_sample]
    rfl
  change (if h : ∀ axis,
    (((windowPlan plan).window axis).inputIndex? (output axis).val (kernel axis)).isSome then
      some (fun axis =>
        (((windowPlan plan).window axis).inputIndex? (output axis).val (kernel axis)).get (h axis))
    else none) = some (sampleIndex plan output kernel)
  rw [dite_eq_left valid]
  congr 1
  funext axis
  simp only [axis_sample]
  rfl

/-- Removing the reduced axes preserves the number of output elements. -/
theorem output_count (plan : Reduction.Plan) :
    LinearIndex.elementCount (windowPlan plan).outputShape =
      LinearIndex.elementCount plan.outputShape := by
  induction plan with
  | scalar => rfl
  | keep extent tail ih =>
    change (keptAxis extent).outputExtent *
      LinearIndex.elementCount (windowPlan tail).outputShape =
      extent * LinearIndex.elementCount tail.outputShape
    rw [kept_output_extent, ih]
  | reduce extent tail ih =>
    change (reducedAxis extent).outputExtent *
      LinearIndex.elementCount (windowPlan tail).outputShape =
      LinearIndex.elementCount tail.outputShape
    rw [reduced_output_extent, Nat.one_mul, ih]

/-- Dropping singleton dimensions preserves the actual logical linear position. -/
theorem output_linearize (plan : Reduction.Plan)
    (output : Index (windowPlan plan).outputShape) :
    (LinearIndex.linearize plan.outputShape (outputIndex plan output)).val =
      (LinearIndex.linearize (windowPlan plan).outputShape output).val := by
  induction plan with
  | scalar => rfl
  | keep extent tail ih =>
    change (output ⟨0, Nat.zero_lt_succ _⟩).val *
      LinearIndex.elementCount tail.outputShape +
      (LinearIndex.linearize tail.outputShape
        (outputIndex tail (fun axis => output axis.succ))).val =
      (output ⟨0, Nat.zero_lt_succ _⟩).val *
      LinearIndex.elementCount (windowPlan tail).outputShape +
      (LinearIndex.linearize (windowPlan tail).outputShape (fun axis => output axis.succ)).val
    exact congrArg₂ (fun count position =>
      (output ⟨0, Nat.zero_lt_succ _⟩).val * count + position)
      (output_count tail).symm (ih _)
  | reduce extent tail ih =>
    have zero : (output ⟨0, Nat.zero_lt_succ _⟩).val = 0 := by
      have bound := (output ⟨0, Nat.zero_lt_succ _⟩).isLt
      change (output ⟨0, Nat.zero_lt_succ _⟩).val < (reducedAxis extent).outputExtent at bound
      have one := reduced_output_extent extent
      omega
    change (LinearIndex.linearize tail.outputShape
      (outputIndex tail (fun axis => output axis.succ))).val =
      (output ⟨0, Nat.zero_lt_succ _⟩).val *
      LinearIndex.elementCount (windowPlan tail).outputShape +
      (LinearIndex.linearize (windowPlan tail).outputShape (fun axis => output axis.succ)).val
    rw [zero, Nat.zero_mul, Nat.zero_add]
    exact ih _

/-- The coordinate deletion is the existing logical reshape, derived without a map premise. -/
theorem output_reshape (plan : Reduction.Plan)
    (output : Index (windowPlan plan).outputShape) :
    outputIndex plan output = Reshape.reshapeIndex plan.outputShape
      (windowPlan plan).outputShape (output_count plan).symm output := by
  unfold Reshape.reshapeIndex
  rw [← LinearIndex.delinearize_linearize plan.outputShape (outputIndex plan output)]
  congr 1
  apply Fin.ext
  exact output_linearize plan output

end TensorRewrite.Theory.FullSpanWindow
