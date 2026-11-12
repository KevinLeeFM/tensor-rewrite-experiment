module

public import TensorRewrite.Theory.PadWindowProof

/-! Fuse nonnegative input Pad into every feature channel of an actual convolution. -/

@[expose] public section

set_option autoImplicit false
set_option backward.isDefEq.respectTransparency false

namespace TensorRewrite.PaperComparison.PadConvolution

open Pilot Theory Theory.Convolution Theory.PadWindow

/-- Convolution applied after the explicit spatial Pad. -/
def outerConv {rank : Nat} (template : Convolution.Plan rank) (padding : PadWindow.Plan rank) :
    Convolution.Plan rank :=
  { template with window := fun axis => outerAxis (padding.padding axis) (padding.window axis) }

/-- Convolution with the derived fused spatial padding and base dilation. -/
def fusedConv {rank : Nat} (template : Convolution.Plan rank) (padding : PadWindow.Plan rank) :
    Convolution.Plan rank :=
  { template with window := fun axis => fusedAxis (padding.padding axis) (padding.window axis) }

/-- Read the same output coordinate after the independently proved output-shape equality. -/
def fusedOutput {rank : Nat} (template : Convolution.Plan rank) (padding : PadWindow.Plan rank)
    (output : OutputIndex (outerConv template padding)) :
    OutputIndex (fusedConv template padding) where
  batch := output.batch
  batchGroup := output.batchGroup
  featureGroup := output.featureGroup
  feature := output.feature
  spatial := outputIndex padding output.spatial

/-- Pad every batch/channel plane by the actual tensor Pad operator. -/
def paddedInput {rank : Nat} {α : Type} [Zero α] (template : Convolution.Plan rank)
    (padding : PadWindow.Plan rank) (input : Input (fusedConv template padding) α) :
    Input (outerConv template padding) α :=
  fun batch channel => pad padding 0 (input batch channel)

/-- Spatial sampling depends on the window, not on convolution channel-group counts. -/
theorem outer_sample {rank : Nat} (template : Convolution.Plan rank) (padding : PadWindow.Plan rank)
    (output : Index (outerConv template padding).outputShape)
    (kernel : Index (outerConv template padding).kernelShape) :
    spatialInput? (outerConv template padding) output kernel =
      ReductionWindow.sample? (outerWindow padding) output kernel := rfl

theorem fused_sample {rank : Nat} (template : Convolution.Plan rank) (padding : PadWindow.Plan rank)
    (output : Index (fusedConv template padding).outputShape)
    (kernel : Index (fusedConv template padding).kernelShape) :
    spatialInput? (fusedConv template padding) output kernel =
      ReductionWindow.sample? (fusedWindow padding) output kernel := rfl

/-- Each weighted channel/kernel contribution is preserved by spatial Pad fusion. -/
theorem term_fusion {rank : Nat} {α : Type} [Semiring α] (template : Convolution.Plan rank)
    (padding : PadWindow.Plan rank) (input : Input (fusedConv template padding) α)
    (kernel : Kernel (outerConv template padding) α)
    (output : OutputIndex (outerConv template padding))
    (position : Fin ((outerConv template padding).inputFeaturesPerGroup *
      LinearIndex.elementCount (outerConv template padding).kernelShape)) :
    term (outerConv template padding) (paddedInput template padding input) kernel output position =
      term (fusedConv template padding) input kernel
        (fusedOutput template padding output) position := by
  let channel := FiniteProduct.row position
  let spatial := LinearIndex.delinearize (outerConv template padding).kernelShape
    (FiniteProduct.column position)
  let inputPlane := input (FiniteProduct.join output.batchGroup output.batch)
    (FiniteProduct.join output.featureGroup channel)
  let weight := kernel output.batchGroup output.featureGroup output.feature channel spatial
  have values := contribution_fusion padding (0 : α) inputPlane output.spatial spatial
  calc
    _ = ReductionWindow.contribution (outerWindow padding) 0 (pad padding 0 inputPlane)
        output.spatial spatial * weight := by
      dsimp only [term, paddedInput, ReductionWindow.contribution]
      rw [outer_sample]
      cases h : ReductionWindow.sample? (outerWindow padding) output.spatial spatial <;>
        simp [channel, spatial, inputPlane, weight]
    _ = ReductionWindow.contribution (fusedWindow padding) 0 inputPlane
        (outputIndex padding output.spatial) spatial * weight := congrArg (· * weight) values
    _ = _ := by
      dsimp only [term, fusedOutput, ReductionWindow.contribution]
      have sampleEq := fused_sample template padding (outputIndex padding output.spatial)
        (LinearIndex.delinearize (fusedConv template padding).kernelShape
          (FiniteProduct.column position))
      rw [sampleEq]
      cases h : ReductionWindow.sample? (fusedWindow padding)
          (outputIndex padding output.spatial) spatial with
      | none =>
        have h2 : ReductionWindow.sample? (fusedWindow padding)
            (outputIndex padding output.spatial)
            (LinearIndex.delinearize (fusedConv template padding).kernelShape
              (FiniteProduct.column position)) = none := h
        simp [h2, channel, spatial, weight]
      | some index =>
        have h2 : ReductionWindow.sample? (fusedWindow padding)
            (outputIndex padding output.spatial)
            (LinearIndex.delinearize (fusedConv template padding).kernelShape
              (FiniteProduct.column position)) = some index := h
        simp [h2, channel, spatial, inputPlane, weight]
        rfl

/-- `conv/rule00`: fuse the actual input Pad across every convolution contribution. -/
theorem convolve_fusion {rank : Nat} {α : Type} [Semiring α] (template : Convolution.Plan rank)
    (padding : PadWindow.Plan rank) (input : Input (fusedConv template padding) α)
    (kernel : Kernel (outerConv template padding) α) :
    convolve (outerConv template padding) (paddedInput template padding input) kernel =
      fun output => convolve (fusedConv template padding) input kernel
        (fusedOutput template padding output) := by
  funext output
  unfold convolve
  apply congrArg List.sum
  apply List.map_congr_left
  intro position _
  exact term_fusion template padding input kernel output position

/-- With paper base dilation one, fused low and high edges are the paper's sums. -/
theorem paper_edges (padding : PaddingAxis) (axis : Axis) (unit : axis.baseDilation = 1) :
    fusedLow padding axis = axis.paddingLow + padding.low ∧
      fusedHigh padding axis = axis.paddingHigh + padding.high ∧
      (fusedAxis padding axis).baseDilation = padding.spacing := by
  refine ⟨by simp [fusedLow, unit], fused_high_unit_base padding axis unit, ?_⟩
  simp [fusedAxis, unit]

#print axioms term_fusion
#print axioms convolve_fusion
#print axioms paper_edges

end TensorRewrite.PaperComparison.PadConvolution
