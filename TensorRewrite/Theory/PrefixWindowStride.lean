module

public import TensorRewrite.Theory.PrefixWindow
public import TensorRewrite.Theory.LatticeIndex
public import TensorRewrite.Theory.ConvolutionPointwiseLemmas

/-! Positive retained-axis strides, with derived legal sampling coordinates. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PrefixWindow

/-- Retained output extent follows from the actual floor-division window geometry. -/
theorem retained_output_extent (extent : Nat) (stride : ℕ+) :
    (retainedAxis extent stride).outputExtent =
      (((extent : Int) - 1) / (stride.val : Int) + 1).toNat := by
  simp [Convolution.Axis.outputExtent, retainedAxis, FullSpanWindow.keptAxis,
    ConvolutionPointwise.dilatedExtent_one]

/-- Every admitted retained output samples a bounded original coordinate at output*stride. -/
theorem retained_bound (extent : Nat) (stride : ℕ+)
    (output : Fin (retainedAxis extent stride).outputExtent) :
    output.val * stride.val < extent := by
  have bound := Nat.lt_of_lt_of_eq output.isLt (retained_output_extent extent stride)
  have positive : (0 : Int) < stride.val := by have := stride.pos; omega
  have quotient : (output.val : Int) ≤ ((extent : Int) - 1) / stride.val := by omega
  have product := Int.mul_le_of_le_ediv positive quotient
  rw [← Int.natCast_mul] at product
  omega

/-- A retained output coordinate maps to the derived bounded affine input coordinate. -/
def retainedIndex (extent : Nat) (stride : ℕ+)
    (output : Fin (retainedAxis extent stride).outputExtent) : Fin extent :=
  ⟨output.val * stride.val, retained_bound extent stride output⟩

/-- Retained sampling returns the derived coordinate, without a shape/index equality premise. -/
theorem retained_sample (extent : Nat) (stride : ℕ+)
    (output : Fin (retainedAxis extent stride).outputExtent)
    (kernel : Fin (retainedAxis extent stride).kernelExtent) :
    (retainedAxis extent stride).inputIndex? output.val kernel =
      some (retainedIndex extent stride output) := by
  apply (LatticeIndex.window_eq_some_iff _ _ _ _).mpr
  have zero : kernel.val = 0 := by have bound := kernel.isLt; change kernel.val < 1 at bound; omega
  simp [Convolution.Axis.basePosition, retainedAxis, FullSpanWindow.keptAxis,
    retainedIndex, zero]

/-- Cumulative output extent equals input extent even when the input is empty. -/
theorem prefix_output_extent (extent : Nat) : (prefixAxis extent).outputExtent = extent := by
  simp [Convolution.Axis.outputExtent, prefixAxis, FullSpanWindow.keptAxis]

end TensorRewrite.Theory.PrefixWindow
