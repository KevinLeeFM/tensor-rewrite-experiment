module

public import TensorRewrite.Theory.PadWindow
public import TensorRewrite.Theory.ConvolutionPointwiseLemmas
public import Mathlib.Tactic.Ring
public import Mathlib.Tactic.LinearCombination

/-! Padding bounds and the geometry of composing two occupied-coordinate samplers. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PadWindow

open Pilot

/-- An original input coordinate occurs within the derived padded shape. -/
theorem occupied_bound (padding : PaddingAxis) (index : Fin padding.inputExtent) :
    padding.low + index.val * padding.spacing < padding.outputExtent := by
  have bound := index.isLt
  have nonzero : padding.inputExtent ≠ 0 := by omega
  have product := Nat.mul_le_mul_right padding.spacing
    (show index.val ≤ padding.inputExtent - 1 by omega)
  simp only [PaddingAxis.outputExtent, Convolution.dilatedExtent, nonzero, ite_false]
  omega

/-- The bounded padded coordinate occupied by an original input coordinate. -/
def embeddedIndex (padding : PaddingAxis) (index : Fin padding.inputExtent) :
    Fin padding.outputExtent :=
  ⟨padding.low + index.val * padding.spacing, occupied_bound padding index⟩

/-- Independent Pad sampling returns an input coordinate exactly at its occupied position. -/
theorem pad_sample_iff (padding : PaddingAxis) (output : Fin padding.outputExtent)
    (index : Fin padding.inputExtent) :
    padding.sample? output = some index ↔
      (output.val : Int) = padding.low + (index.val : Int) * padding.spacing := by
  change LatticeIndex.decode? _ _ _ _ = some index ↔ _
  rw [LatticeIndex.decode_eq_some_iff]
  omega

/-- Sampling an embedded coordinate recovers the original input. -/
theorem sample_embedded (padding : PaddingAxis) (index : Fin padding.inputExtent) :
    padding.sample? (embeddedIndex padding index) = some index := by
  apply (pad_sample_iff _ _ _).mpr
  simp only [embeddedIndex, Int.natCast_add, Int.natCast_mul]

/-- Moving Pad's low edge through base dilation gives the fused sample position. -/
theorem fused_position (padding : PaddingAxis) (window : Convolution.Axis)
    (output : Nat) (kernel : Fin window.kernelExtent) :
    (fusedAxis padding window).basePosition output kernel =
      (outerAxis padding window).basePosition output kernel -
        (padding.low : Int) * window.baseDilation := by
  cases reversed : window.reversed <;>
    simp only [Convolution.Axis.basePosition, fusedAxis, outerAxis, fusedLow, reversed] <;> ring

/-- The composed high edge preserves the complete output extent, including empty input. -/
theorem fused_output_extent (padding : PaddingAxis) (window : Convolution.Axis) :
    (outerAxis padding window).outputExtent = (fusedAxis padding window).outputExtent := by
  apply congrArg (fun numerator : Int =>
    (numerator / (window.stride : Int) + 1).toNat)
  dsimp only [outerAxis, fusedAxis, fusedLow, fusedHigh]
  ring

/-- Nonempty dilation extents have their ordinary affine integer expression. -/
theorem dilated_extent_nonempty (extent spacing : Nat) (nonempty : 0 < extent) :
    (Convolution.dilatedExtent extent spacing : Int) =
      ((extent : Int) - 1) * spacing + 1 := by
  have nonzero : extent ≠ 0 := by omega
  simp only [Convolution.dilatedExtent, nonzero, ite_false, Int.natCast_add, Int.natCast_mul]
  rw [Int.natCast_sub (by omega : 1 ≤ extent)]
  rfl

/-- On nonempty input, the derived high edge is the familiar dilation-scaled sum. -/
theorem fused_high_nonempty (padding : PaddingAxis) (window : Convolution.Axis)
    (nonempty : 0 < padding.inputExtent) :
    fusedHigh padding window = window.paddingHigh +
      (padding.high : Int) * window.baseDilation := by
  have padded : 0 < padding.outputExtent := by
    have bound := occupied_bound padding ⟨0, nonempty⟩
    omega
  have extent : (padding.outputExtent : Int) = padding.low +
      ((padding.inputExtent : Int) - 1) * padding.spacing + 1 + padding.high := by
    simp only [PaddingAxis.outputExtent, Int.natCast_add,
      dilated_extent_nonempty _ _ nonempty]
    ring
  simp only [fusedHigh, dilated_extent_nonempty _ _ padded,
    dilated_extent_nonempty _ _ nonempty, extent, Int.natCast_mul]
  ring

/-- With no outer base dilation, the high edge reduces to the usual sum. -/
theorem fused_high_unit_base (padding : PaddingAxis) (window : Convolution.Axis)
    (unit : window.baseDilation = 1) :
    fusedHigh padding window = window.paddingHigh + padding.high := by
  simp only [fusedHigh, unit, ConvolutionPointwise.dilatedExtent_one,
    Int.natCast_one, mul_one, PaddingAxis.outputExtent, Int.natCast_add]
  ring

/-- Axis sampling through actual Pad is exactly the fused axis sampler in the same order. -/
theorem axis_compose (padding : PaddingAxis) (window : Convolution.Axis) (output : Nat)
    (kernel : Fin window.kernelExtent) :
    ((outerAxis padding window).inputIndex? output kernel).bind padding.sample? =
      (fusedAxis padding window).inputIndex? output kernel := by
  apply Option.ext
  intro index
  refine Option.bind_eq_some_iff.trans ?_
  constructor
  · rintro ⟨padded, sampled, occupied⟩
    apply (LatticeIndex.window_eq_some_iff _ _ _ _).mpr
    have outer := (LatticeIndex.window_eq_some_iff _ _ _ _).mp sampled
    have pad := (pad_sample_iff _ _ _).mp occupied
    calc
      _ = (outerAxis padding window).basePosition output kernel -
          (padding.low : Int) * window.baseDilation := fused_position _ _ _ _
      _ = _ := by
        change (outerAxis padding window).basePosition output kernel =
          (padded.val : Int) * window.baseDilation at outer
        rw [outer, pad]
        simp only [fusedAxis, Int.natCast_mul]
        ring
  · intro sampled
    have fused := (LatticeIndex.window_eq_some_iff _ _ _ _).mp sampled
    refine ⟨embeddedIndex padding index, ?_, sample_embedded padding index⟩
    apply (LatticeIndex.window_eq_some_iff _ _ _ _).mpr
    rw [fused_position] at fused
    change (outerAxis padding window).basePosition output kernel =
      (padding.low + index.val * padding.spacing : Nat) * (window.baseDilation : Int)
    push_cast
    dsimp only [fusedAxis] at fused
    push_cast at fused
    linear_combination fused

/-- Fused and original windows have identical output shapes, derived axis by axis. -/
theorem output_shape {rank : Nat} (plan : Plan rank) :
    (outerWindow plan).outputShape = (fusedWindow plan).outputShape := by
  funext axis
  exact fused_output_extent _ _

/-- Transport output bounds across the derived equality without changing coordinate values. -/
def outputIndex {rank : Nat} (plan : Plan rank) (output : Index (outerWindow plan).outputShape) :
    Index (fusedWindow plan).outputShape :=
  fun axis => Fin.cast (congrFun (output_shape plan) axis) (output axis)

end TensorRewrite.Theory.PadWindow
