module

public import TensorRewrite.Theory.BroadcastWindow
public import TensorRewrite.Theory.LatticeIndex
public import TensorRewrite.Theory.ConvolutionPointwiseLemmas

/-! The covering inequalities determine the unique live kernel coordinate on a singleton axis. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BroadcastWindow

/-- Every admitted output has a bounded nonnegative offset to the sole occupied input. -/
theorem covered_offset (expansion : Expansion) (covers : expansion.Covers)
    (output : Fin expansion.axis.outputExtent) :
    0 ≤ expansion.paddingLow - (output.val : Int) * expansion.stride.val ∧
      expansion.paddingLow - (output.val : Int) * expansion.stride.val <
        expansion.kernelExtent := by
  rcases covers with empty | ⟨low, upper, last⟩
  · have bound := output.isLt
    omega
  · have bounded : output.val ≤ expansion.axis.outputExtent - 1 := by have := output.isLt; omega
    have product := Nat.mul_le_mul_right expansion.stride.val bounded
    have cast : (output.val : Int) * expansion.stride.val ≤
        ((expansion.axis.outputExtent - 1) * expansion.stride.val : Nat) := by
      exact_mod_cast product
    have nonnegative : 0 ≤ (output.val : Int) * expansion.stride.val :=
      Int.mul_nonneg (by omega) (by omega)
    omega

/-- The unreversed kernel coordinate at which a singleton input occurs. -/
def offsetIndex (expansion : Expansion) (covers : expansion.Covers)
    (output : Fin expansion.axis.outputExtent) : Fin expansion.kernelExtent :=
  ⟨(expansion.paddingLow - (output.val : Int) * expansion.stride.val).toNat,
    (Int.toNat_lt (covered_offset expansion covers output).1).mpr
      (covered_offset expansion covers output).2⟩

/-- Account for the actual kernel reversal while retaining the unique live position. -/
def expansionKernel (expansion : Expansion) (covers : expansion.Covers)
    (output : Fin expansion.axis.outputExtent) : Fin expansion.kernelExtent :=
  if expansion.reversed then (offsetIndex expansion covers output).rev
  else offsetIndex expansion covers output

/-- A singleton's selected kernel coordinate has base position exactly zero. -/
theorem expansion_live_position (expansion : Expansion) (covers : expansion.Covers)
    (output : Fin expansion.axis.outputExtent) :
    expansion.axis.basePosition output.val (expansionKernel expansion covers output) = 0 := by
  have nonnegative := (covered_offset expansion covers output).1
  cases reversed : expansion.reversed <;>
    simp [Convolution.Axis.basePosition, Expansion.axis, expansionKernel, reversed,
      offsetIndex, Int.toNat_of_nonneg nonnegative]

/-- The live position returns the sole original input coordinate. -/
theorem expansion_sample (expansion : Expansion) (covers : expansion.Covers)
    (output : Fin expansion.axis.outputExtent) :
    expansion.axis.inputIndex? output.val (expansionKernel expansion covers output) =
      some ⟨0, by change 0 < 1; decide⟩ := by
  apply (LatticeIndex.window_eq_some_iff _ _ _ _).mpr
  rw [expansion_live_position]
  simp

/-- Any successful singleton sample must occur at exactly the selected kernel position. -/
theorem expansion_unique (expansion : Expansion) (covers : expansion.Covers)
    (output : Fin expansion.axis.outputExtent) (kernel : Fin expansion.kernelExtent)
    (input : Fin expansion.axis.inputExtent)
    (sample : expansion.axis.inputIndex? output.val kernel = some input) :
    kernel = expansionKernel expansion covers output := by
  have position := (LatticeIndex.window_eq_some_iff _ _ _ _).mp sample
  have zero : input.val = 0 := by have bound := input.isLt; change input.val < 1 at bound; omega
  have nonnegative := (covered_offset expansion covers output).1
  have offset : ((offsetIndex expansion covers output).val : Int) =
      expansion.paddingLow - (output.val : Int) * expansion.stride.val := by
    exact Int.toNat_of_nonneg nonnegative
  cases reversed : expansion.reversed
  · apply Fin.ext
    simp only [expansionKernel, reversed, Bool.false_eq_true, ite_false]
    simp only [Convolution.Axis.basePosition, Expansion.axis, reversed, Bool.false_eq_true,
      ite_false, zero, Nat.cast_zero, zero_mul, Int.natCast_one, mul_one] at position
    omega
  · have same : kernel.rev = offsetIndex expansion covers output := by
      apply Fin.ext
      simp only [Convolution.Axis.basePosition, Expansion.axis, reversed, ite_true, zero,
        Nat.cast_zero, zero_mul, Int.natCast_one, mul_one] at position
      omega
    simpa only [expansionKernel, reversed, ite_true, Fin.rev_rev] using congrArg Fin.rev same

end TensorRewrite.Theory.BroadcastWindow
