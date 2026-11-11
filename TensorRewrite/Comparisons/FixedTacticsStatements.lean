module

public import Aesop
public import Lean.Elab.Command
public import Mathlib.Algebra.BigOperators.Group.Finset.Sigma
public import FloatLib.Floats.Formats.BinaryInterchange.Arithmetic.SignedSemantics.Core
public import TensorRewrite.Pilot.Indexing
public import TensorRewrite.Pilot.Contraction
public import TensorRewrite.Pilot.Reduction
public import TensorRewrite.Theory.Convolution
public import TensorRewrite.Theory.ConvolutionPointwise
public import TensorRewrite.Theory.LogicalFamily

/-! Frozen exact reviewed statements; no project rewrite proofs are imported. -/

@[expose] public section

set_option autoImplicit false
-- Original named hypotheses are preserved even when unused by the proposition.
set_option linter.unusedVariables false

namespace TensorRewrite.Theory.FloatNegation
open FloatLib.Floats.Formats.BinaryInterchange

/-- The unchanged reviewed target TensorRewrite.Theory.FloatNegation.scalar_involution. -/
def case_000 : Prop :=
  ∀ {format : FloatFormat} (x : Model format),
    Model.neg (Model.neg x) = x

end TensorRewrite.Theory.FloatNegation

namespace TensorRewrite.Theory.FloatNegation
open FloatLib.Floats.Formats.BinaryInterchange

/-- The unchanged reviewed target TensorRewrite.Theory.FloatNegation.tensor_involution. -/
def case_001 : Prop :=
  ∀ {rank : Nat} {shape : Pilot.Shape rank} {format : FloatFormat}
    (x : Pilot.Tensor shape (Model format)),
    Pilot.Tensor.map Model.neg (Pilot.Tensor.map Model.neg x) = x

end TensorRewrite.Theory.FloatNegation

namespace TensorRewrite.Theory.FloatNegation
open FloatLib.Floats.Formats.BinaryInterchange

/-- The unchanged reviewed target TensorRewrite.Theory.FloatNegation.reindex_neg. -/
def case_002 : Prop :=
  ∀ {inputRank outputRank : Nat}
    {inputShape : Pilot.Shape inputRank} {outputShape : Pilot.Shape outputRank}
    {format : FloatFormat} (indices : Pilot.Index outputShape → Pilot.Index inputShape)
    (x : Pilot.Tensor inputShape (Model format)),
    Pilot.Tensor.reindex indices (Pilot.Tensor.map Model.neg x) =
      Pilot.Tensor.map Model.neg (Pilot.Tensor.reindex indices x)

end TensorRewrite.Theory.FloatNegation

namespace TensorRewrite.Theory.FloatNegation
open FloatLib.Floats.Formats.BinaryInterchange

/-- The unchanged reviewed target TensorRewrite.Theory.FloatNegation.reverse_neg. -/
def case_003 : Prop :=
  ∀ {rank : Nat} {shape : Pilot.Shape rank} {format : FloatFormat}
    (axes : Fin rank → Bool) (x : Pilot.Tensor shape (Model format)),
    Pilot.Tensor.reverse axes (Pilot.Tensor.map Model.neg x) =
      Pilot.Tensor.map Model.neg (Pilot.Tensor.reverse axes x)

end TensorRewrite.Theory.FloatNegation

namespace TensorRewrite.Theory.FiniteSum
open Pilot
open Pilot.LinearIndex

/-- The unchanged reviewed target TensorRewrite.Theory.FiniteSum.foldl_add_eq_sum. -/
def case_004 : Prop :=
  ∀ {α : Type} [AddMonoid α] (values : List α) (initial : α),
    values.foldl (· + ·) initial = initial + values.sum

end TensorRewrite.Theory.FiniteSum

namespace TensorRewrite.Theory.FiniteSum
open Pilot
open Pilot.LinearIndex

/-- The unchanged reviewed target TensorRewrite.Theory.FiniteSum.reduce_add_eq_fiber_sum. -/
def case_005 : Prop :=
  ∀ {α : Type} [AddMonoid α] (plan : Reduction.Plan)
    (input : Tensor plan.inputShape α),
    Reduction.reduceTensor plan (· + ·) 0 input =
      fun output => (Reduction.fiberValues plan input output).sum

end TensorRewrite.Theory.FiniteSum

namespace TensorRewrite.Theory.FiniteSum
open Pilot
open Pilot.LinearIndex

/-- The unchanged reviewed target TensorRewrite.Theory.FiniteSum.sum_swap. -/
def case_006 : Prop :=
  ∀ {α I J : Type} [AddCommMonoid α] [Fintype I] [Fintype J]
    (input : I → J → α),
    (∑ i, ∑ j, input i j) = ∑ j, ∑ i, input i j

end TensorRewrite.Theory.FiniteSum

namespace TensorRewrite.Theory.FiniteSum
open Pilot
open Pilot.LinearIndex

/-- The unchanged reviewed target TensorRewrite.Theory.FiniteSum.sum_add. -/
def case_007 : Prop :=
  ∀ {α I : Type} [AddCommMonoid α] [Fintype I] (x y : I → α),
    (∑ i, x i) + (∑ i, y i) = ∑ i, (x i + y i)

end TensorRewrite.Theory.FiniteSum

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.inputIndex?_negative. -/
def case_008 : Prop :=
  ∀ (axis : Axis) (output : Nat) (kernel : Fin axis.kernelExtent)
    (negative : axis.basePosition output kernel < 0),
    axis.inputIndex? output kernel = none

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.basePosition_reverse. -/
def case_009 : Prop :=
  ∀ (axis : Axis) (output : Nat) (kernel : Fin axis.kernelExtent),
    Axis.basePosition { axis with reversed := !axis.reversed } output kernel.rev =
      axis.basePosition output kernel

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.inputIndex?_position. -/
def case_010 : Prop :=
  ∀ (axis : Axis) (output : Nat) (kernel : Fin axis.kernelExtent)
    (index : Fin axis.inputExtent) (sample : axis.inputIndex? output kernel = some index),
    (index.val : Int) * axis.baseDilation = axis.basePosition output kernel

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.term_zero_kernel. -/
def case_011 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape)),
    term plan input (fun _ _ _ _ _ => 0) output position = 0

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.term_zero_input. -/
def case_012 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (kernel : Kernel plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape)),
    term plan (fun _ _ _ => 0) kernel output position = 0

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.convolve_zero_kernel. -/
def case_013 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α),
    convolve plan input (fun _ _ _ _ _ => 0) = fun _ => 0

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.convolve_zero_input. -/
def case_014 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (kernel : Kernel plan α),
    convolve plan (fun _ _ _ => 0) kernel = fun _ => 0

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.convolve_empty_fiber. -/
def case_015 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α)
    (empty : plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape = 0),
    convolve plan input kernel = fun _ => 0

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.spatialInput?_empty. -/
def case_016 : Prop :=
  ∀ {rank : Nat} (plan : Plan rank)
    (empty : Pilot.LinearIndex.elementCount plan.inputShape = 0)
    (output : Pilot.Index plan.outputShape) (kernel : Pilot.Index plan.kernelShape),
    spatialInput? plan output kernel = none

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.term_empty_spatial_input. -/
def case_017 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape))
    (empty : Pilot.LinearIndex.elementCount plan.inputShape = 0),
    term plan input kernel output position = 0

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.convolve_empty_spatial_input. -/
def case_018 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α)
    (empty : Pilot.LinearIndex.elementCount plan.inputShape = 0),
    convolve plan input kernel = fun _ => 0

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.convolve_empty_kernel. -/
def case_019 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α)
    (empty : Pilot.LinearIndex.elementCount plan.kernelShape = 0),
    convolve plan input kernel = fun _ => 0

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.convolve_no_channels. -/
def case_020 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α) (empty : plan.inputFeaturesPerGroup = 0),
    convolve plan input kernel = fun _ => 0

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.term_kernel_add. -/
def case_021 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (f g : Kernel plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape)),
    term plan input (fun b h o c s => f b h o c s + g b h o c s) output position =
      term plan input f output position + term plan input g output position

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.term_input_add. -/
def case_022 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (x y : Input plan α) (kernel : Kernel plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape)),
    term plan (fun b c s => x b c s + y b c s) kernel output position =
      term plan x kernel output position + term plan y kernel output position

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.term_kernel_scale. -/
def case_023 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α)
    (weights : Fin plan.batchGroups → Fin plan.featureGroups → Fin plan.outputFeaturesPerGroup → α)
    (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape)),
    term plan input (fun b h o c s => kernel b h o c s * weights b h o)
      output position =
      term plan input kernel output position *
        weights output.batchGroup output.featureGroup output.feature

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.convolve_kernel_add. -/
def case_024 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (f g : Kernel plan α),
    convolve plan input (fun b h o c s => f b h o c s + g b h o c s) =
      fun output => convolve plan input f output + convolve plan input g output

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.convolve_input_add. -/
def case_025 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (x y : Input plan α) (kernel : Kernel plan α),
    convolve plan (fun b c s => x b c s + y b c s) kernel =
      fun output => convolve plan x kernel output + convolve plan y kernel output

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.convolve_kernel_scale. -/
def case_026 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α)
    (weights :
      Fin plan.batchGroups → Fin plan.featureGroups → Fin plan.outputFeaturesPerGroup → α),
    convolve plan input (fun b h o c s => kernel b h o c s * weights b h o) =
      fun output => convolve plan input kernel output *
        weights output.batchGroup output.featureGroup output.feature

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.Convolution.convolve_bias_scale. -/
def case_027 : Prop :=
  ∀ {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α) (bias : OutputIndex plan → α)
    (weights : Fin plan.batchGroups → Fin plan.featureGroups → Fin plan.outputFeaturesPerGroup → α)
    (output : OutputIndex plan),
    (convolve plan input kernel output + bias output) *
        weights output.batchGroup output.featureGroup output.feature =
      convolve plan input (fun b h o c s => kernel b h o c s * weights b h o) output +
        bias output * weights output.batchGroup output.featureGroup output.feature

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.ConvolutionPointwise
open Pilot
open Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.ConvolutionPointwise.dilatedExtent_one. -/
def case_028 : Prop :=
  ∀ (extent : Nat),
    dilatedExtent extent 1 = extent

end TensorRewrite.Theory.ConvolutionPointwise

namespace TensorRewrite.Theory.ConvolutionPointwise
open Pilot
open Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.ConvolutionPointwise.output_extent_eq. -/
def case_029 : Prop :=
  ∀ (axis : Axis) (pointwise : IsPointwiseAxis axis),
    axis.outputExtent = axis.inputExtent

end TensorRewrite.Theory.ConvolutionPointwise

namespace TensorRewrite.Theory.ConvolutionPointwise
open Pilot
open Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.ConvolutionPointwise.output_shape_eq. -/
def case_030 : Prop :=
  ∀ {rank : Nat} (plan : Plan rank) (pointwise : IsPointwise plan),
    plan.outputShape = plan.inputShape

end TensorRewrite.Theory.ConvolutionPointwise

namespace TensorRewrite.Theory.ConvolutionPointwise
open Pilot
open Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.ConvolutionPointwise.elementCount_unit. -/
def case_031 : Prop :=
  ∀ {rank : Nat} (shape : Shape rank) (unit : ∀ axis, shape axis = 1),
    LinearIndex.elementCount shape = 1

end TensorRewrite.Theory.ConvolutionPointwise

namespace TensorRewrite.Theory.ConvolutionPointwise
open Pilot
open Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.ConvolutionPointwise.kernel_count_eq_one. -/
def case_032 : Prop :=
  ∀ {rank : Nat} (plan : Plan rank) (pointwise : IsPointwise plan),
    LinearIndex.elementCount plan.kernelShape = 1

end TensorRewrite.Theory.ConvolutionPointwise

namespace TensorRewrite.Theory.ConvolutionPointwise
open Pilot
open Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.ConvolutionPointwise.kernel_index_unique. -/
def case_033 : Prop :=
  ∀ {rank : Nat} (plan : Plan rank)
    (unitKernel : ∀ axis, plan.kernelShape axis = 1) (index : Index plan.kernelShape),
    index = kernelIndex plan unitKernel

end TensorRewrite.Theory.ConvolutionPointwise

namespace TensorRewrite.Theory.ConvolutionPointwise
open Pilot
open Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.ConvolutionPointwise.base_position_eq. -/
def case_034 : Prop :=
  ∀ (axis : Axis) (pointwise : IsPointwiseAxis axis)
    (output : Nat) (kernel : Fin axis.kernelExtent),
    axis.basePosition output kernel = output

end TensorRewrite.Theory.ConvolutionPointwise

namespace TensorRewrite.Theory.ConvolutionPointwise
open Pilot
open Convolution

/-- The unchanged reviewed target TensorRewrite.Theory.ConvolutionPointwise.sum_kernel_positions. -/
def case_035 : Prop :=
  ∀ {rank : Nat} {α : Type} [AddCommMonoid α] (plan : Plan rank)
    (pointwise : IsPointwise plan) (value : Fin plan.inputFeaturesPerGroup → α),
    (∑ position : Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape),
      value (FiniteProduct.row position)) = ∑ channel, value channel

end TensorRewrite.Theory.ConvolutionPointwise

namespace TensorRewrite.Theory.LogicalFamily
open Pilot

/-- The unchanged reviewed target TensorRewrite.Theory.LogicalFamily.rewrite_sound. -/
def case_036 : Prop :=
  ∀ {domain : Domain} {rank : Nat} {shape : Shape rank}
    (rule : Rule domain) (inputs : Nat → Tensor shape domain.Value)
    (condition : rule.Condition inputs),
    rule.lhs.eval inputs = rule.rhs.eval inputs

end TensorRewrite.Theory.LogicalFamily

namespace TensorRewrite.Theory.LogicalFamily
open Pilot

/-- The unchanged reviewed target TensorRewrite.Theory.LogicalFamily.allRules_complete. -/
def case_037 : Prop :=
  ∀ {domain : Domain} (rule : Rule domain),
    rule ∈ allRules domain

end TensorRewrite.Theory.LogicalFamily

namespace TensorRewrite.Theory.LogicalFamily
open Pilot

/-- The unchanged reviewed target TensorRewrite.Theory.LogicalFamily.allRules_nodup. -/
def case_038 : Prop :=
  ∀ (domain : Domain),
    (allRules domain).Nodup

end TensorRewrite.Theory.LogicalFamily

namespace TensorRewrite.Theory.LogicalFamily
open Pilot

/-- The unchanged reviewed target TensorRewrite.Theory.LogicalFamily.word_keys_uniform. -/
def case_039 : Prop :=
  ∀ (width : Nat),
    (allRules (.word width)).map Rule.key = (allRules (.word 0)).map Rule.key

end TensorRewrite.Theory.LogicalFamily

namespace TensorRewrite.Theory.LogicalFamily
open Pilot

/-- The unchanged reviewed target TensorRewrite.Theory.LogicalFamily.predicate_count. -/
def case_040 : Prop :=
  (allRules .predicate).length = 12

end TensorRewrite.Theory.LogicalFamily

namespace TensorRewrite.Theory.LogicalFamily
open Pilot

/-- The unchanged reviewed target TensorRewrite.Theory.LogicalFamily.word_count. -/
def case_041 : Prop :=
  ∀ (width : Nat),
    (allRules (.word width)).length = 8

end TensorRewrite.Theory.LogicalFamily

namespace TensorRewrite.Theory.ContractionAlgebra
open Pilot
open Pilot.Contraction

/-- The unchanged reviewed target TensorRewrite.Theory.ContractionAlgebra.dot_add_left. -/
def case_042 : Prop :=
  ∀ {α : Type} [Semiring α] {batch left right contracting : Nat}
    (plan : Plan batch left right contracting)
    (x y : Tensor plan.lhsShape α) (z : Tensor plan.rhsShape α),
    dotTensor plan (· + ·) 0 (· * ·) id (Tensor.map₂ (· + ·) x y) z =
      Tensor.map₂ (· + ·) (dotTensor plan (· + ·) 0 (· * ·) id x z)
        (dotTensor plan (· + ·) 0 (· * ·) id y z)

end TensorRewrite.Theory.ContractionAlgebra

namespace TensorRewrite.Theory.ContractionAlgebra
open Pilot
open Pilot.Contraction

/-- The unchanged reviewed target TensorRewrite.Theory.ContractionAlgebra.dot_add_right. -/
def case_043 : Prop :=
  ∀ {α : Type} [Semiring α] {batch left right contracting : Nat}
    (plan : Plan batch left right contracting)
    (x : Tensor plan.lhsShape α) (y z : Tensor plan.rhsShape α),
    dotTensor plan (· + ·) 0 (· * ·) id x (Tensor.map₂ (· + ·) y z) =
      Tensor.map₂ (· + ·) (dotTensor plan (· + ·) 0 (· * ·) id x y)
        (dotTensor plan (· + ·) 0 (· * ·) id x z)

end TensorRewrite.Theory.ContractionAlgebra

