module

public import TensorRewrite.Theory.PrefixWindowLemmas

/-! The actual bounded prefix sampler: leading padding followed by original coordinates. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PrefixWindow

open Pilot

/-- The scan window's padding and valid prefix lengths partition its kernel extent. -/
theorem padding_partition {rank : Nat} (plan : Plan rank)
    (output : Index (windowPlan plan).outputShape) :
    paddingCount plan output + (coordinate plan (outputIndex plan output)).val + 1 =
      scanExtent plan := by
  have bound := (coordinate plan (outputIndex plan output)).isLt
  unfold paddingCount
  omega

/-- A valid kernel position gives a bounded original scan coordinate. -/
def sampledIndex {rank : Nat} (plan : Plan rank) (output : Index (windowPlan plan).outputShape)
    (kernel : Fin (scanExtent plan)) (valid : paddingCount plan output ≤ kernel.val) :
    Index (windowPlan plan).inputShape :=
  replaceCoordinate plan (outputIndex plan output) ⟨kernel.val - paddingCount plan output, by
    have bound := kernel.isLt
    omega⟩

/-- Valid sampling returns the direct original coordinate on every axis. -/
theorem sample_axis {rank : Nat} (plan : Plan rank) (output : Index (windowPlan plan).outputShape)
    (kernel : Fin (scanExtent plan)) (valid : paddingCount plan output ≤ kernel.val)
    (axis : Fin rank) :
    ((windowPlan plan).window axis).inputIndex? (output axis).val (kernelIndex plan kernel axis) =
      some (sampledIndex plan output kernel valid axis) := by
  induction plan with
  | scan extent tail stride =>
    refine Fin.cases ?_ (fun axis => ?_) axis
    · apply (LatticeIndex.window_eq_some_iff _ _ _ _).mpr
      have partition := padding_partition (Plan.scan extent tail stride) output
      change extent - 1 - (output ⟨0, Nat.zero_lt_succ _⟩).val ≤ kernel.val at valid
      change extent - 1 - (output ⟨0, Nat.zero_lt_succ _⟩).val +
        (output ⟨0, Nat.zero_lt_succ _⟩).val + 1 = extent at partition
      change (output ⟨0, Nat.zero_lt_succ _⟩).val * (1 : Int) + kernel.val * 1 -
        ((extent : Int) - 1) =
        (kernel.val - paddingCount (Plan.scan extent tail stride) output : Nat) * 1
      change (output ⟨0, Nat.zero_lt_succ _⟩).val * (1 : Int) + kernel.val * 1 -
        ((extent : Int) - 1) =
        (kernel.val - (extent - 1 - (output ⟨0, Nat.zero_lt_succ _⟩).val) : Nat) * 1
      omega
    · exact retained_sample (tail axis) (stride axis) _ _
  | keep extent stride tail ih =>
    refine Fin.cases (retained_sample extent stride _ _) (fun axis => ?_) axis
    exact ih (fun axis => output axis.succ) kernel valid axis

/-- Every valid prefix position assembles the proved bounded coordinate. -/
theorem sample_valid {rank : Nat} (plan : Plan rank)
    (output : Index (windowPlan plan).outputShape) (kernel : Fin (scanExtent plan))
    (valid : paddingCount plan output ≤ kernel.val) :
    ReductionWindow.sample? (windowPlan plan) output (kernelIndex plan kernel) =
      some (sampledIndex plan output kernel valid) := by
  apply (LatticeIndex.assemble_eq_some_iff _ _).mpr
  intro axis
  exact sample_axis plan output kernel valid axis

/-- A leading padding position fails on the scan axis, wherever that axis occurs. -/
theorem negative_axis {rank : Nat} (plan : Plan rank)
    (output : Index (windowPlan plan).outputShape) (kernel : Fin (scanExtent plan))
    (invalid : kernel.val < paddingCount plan output) :
    ∃ axis, ((windowPlan plan).window axis).inputIndex? (output axis).val
      (kernelIndex plan kernel axis) = none := by
  induction plan with
  | scan extent tail stride =>
    refine ⟨⟨0, Nat.zero_lt_succ _⟩, ?_⟩
    apply Convolution.inputIndex?_negative
    change kernel.val < extent - 1 - (output ⟨0, Nat.zero_lt_succ _⟩).val at invalid
    change (output ⟨0, Nat.zero_lt_succ _⟩).val * (1 : Int) + kernel.val * 1 -
      ((extent : Int) - 1) < 0
    omega
  | keep extent stride tail ih =>
    obtain ⟨axis, absent⟩ := ih (fun axis => output axis.succ) kernel invalid
    exact ⟨axis.succ, absent⟩

/-- Every leading padding position gives no input sample; it remains a fold contribution. -/
theorem sample_invalid {rank : Nat} (plan : Plan rank)
    (output : Index (windowPlan plan).outputShape) (kernel : Fin (scanExtent plan))
    (invalid : kernel.val < paddingCount plan output) :
    ReductionWindow.sample? (windowPlan plan) output (kernelIndex plan kernel) = none := by
  cases sampled : ReductionWindow.sample? (windowPlan plan) output (kernelIndex plan kernel) with
  | none => rfl
  | some index =>
    have every := (LatticeIndex.assemble_eq_some_iff _ index).mp sampled
    obtain ⟨axis, absent⟩ := negative_axis plan output kernel invalid
    have impossible := absent.symm.trans (every axis)
    cases impossible

/-- An additive finite range splits into two ordered blocks, without a permutation. -/
theorem map_finRange_add {α : Type} (first second : Nat) (value : Fin (first + second) → α) :
    (List.finRange (first + second)).map value =
      (List.finRange first).map (fun position => value ⟨position.val, by omega⟩) ++
      (List.finRange second).map (fun position => value ⟨first + position.val, by omega⟩) := by
  rw [← List.ofFn_eq_map, List.ofFn_add]
  simp only [List.ofFn_eq_map]
  rfl

/-- Split actual kernel positions into their leading-padding and inclusive-prefix blocks. -/
theorem split_kernel_range {rank : Nat} {α : Type} (plan : Plan rank)
    (output : Index (windowPlan plan).outputShape) (value : Fin (scanExtent plan) → α) :
    (List.finRange (scanExtent plan)).map value =
      (List.finRange (paddingCount plan output)).map (fun position => value ⟨position.val, by
        have partition := padding_partition plan output
        have bound := position.isLt
        omega⟩) ++
      (List.finRange ((coordinate plan (outputIndex plan output)).val + 1)).map
        (fun position => value ⟨paddingCount plan output + position.val, by
          have partition := padding_partition plan output
          have bound := position.isLt
          omega⟩) := by
  have same : paddingCount plan output +
      ((coordinate plan (outputIndex plan output)).val + 1) = scanExtent plan := by
    have partition := padding_partition plan output
    omega
  exact (ConvolutionOrdered.map_finRange_cast same value).symm.trans
    (map_finRange_add _ _ (fun position => value (Fin.cast same position)))

end TensorRewrite.Theory.PrefixWindow
