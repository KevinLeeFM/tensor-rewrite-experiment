module

public import TensorRewrite.Theory.ConvolutionOrderedProof
public import TensorRewrite.Libraries.FloatingPoint
public import FloatLib.Floats.Formats.BinaryInterchange.Configured.Value.Core

/-! Stored-value binary32 consequences of the explicit ordered convolution contract.
The scalar operations return values only. Flags, FMA and external schedules
are outside this model. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConvolutionFloat

open Pilot ConvolutionPointwise ConvolutionDot FloatLib.Floats

/-- Pointwise convolution and matrix Dot preserve identical binary32 products and additions,
including exceptional values and signed zeros, under the explicitly shared ordered schedule. -/
theorem binary32_pointwise_dot {rank : Nat} (plan : Convolution.Plan rank)
    (pointwise : IsPointwise plan) (initial padding : Binary32)
    (input : Convolution.Input plan Binary32) (kernel : Convolution.Kernel plan Binary32)
    (output : Convolution.OutputIndex plan) :
    ConvolutionOrdered.convolve plan ExecFloat.add initial padding ExecFloat.mul id
      input kernel output =
      Contraction.dotTensor (matrixPlan plan) ExecFloat.add initial ExecFloat.mul id
        (lhsMatrix plan input output.batchGroup output.featureGroup)
        (rhsMatrix plan (fun axis => (pointwise axis).unitKernel) kernel
          output.batchGroup output.featureGroup)
        (dotOutput plan (output_shape_eq plan pointwise) output) :=
  ConvolutionOrdered.convolve_eq_dot plan pointwise ExecFloat.add initial padding ExecFloat.mul id
    input kernel output

/-- The complete ordered binary32 value model agrees with the library's reference scalar operations.
This holds for all modeled windows and the same chosen padding contribution/initializer. -/
theorem binary32_reference_eq {rank : Nat} (plan : Convolution.Plan rank)
    (initial padding : Binary32) (input : Convolution.Input plan Binary32)
    (kernel : Convolution.Kernel plan Binary32) :
    ConvolutionOrdered.convolve plan ExecFloat.add initial padding ExecFloat.mul id input kernel =
      ConvolutionOrdered.convolve plan ExecFloat.Spec.add initial padding ExecFloat.Spec.mul id
        input kernel := by
  have addition : (fun x y : Binary32 => ExecFloat.add x y) =
      (fun x y : Binary32 => ExecFloat.Spec.add x y) := by
    funext x y
    exact ExecFloat.Proof.add_eq_spec x y
  have multiplication : (fun x y : Binary32 => ExecFloat.mul x y) =
      (fun x y : Binary32 => ExecFloat.Spec.mul x y) := by
    funext x y
    exact ExecFloat.Proof.mul_eq_spec x y
  exact congrArg₂
    (fun (add multiply : Binary32 → Binary32 → Binary32) =>
      ConvolutionOrdered.convolve plan add initial padding multiply id input kernel)
    addition multiplication

local notation "b32(" value ")" => (ExecFloat.Binary.ofNatBits value : Binary32)

/-- Removing a positive-zero initialized fold can change the stored sign of a one-product result. -/
theorem binary32_fold_omission_refuted :
    ExecFloat.Binary.toNatBits
      (ExecFloat.add b32(0) (ExecFloat.mul b32(0x80000000) b32(0x3f800000))) ≠
      ExecFloat.Binary.toNatBits (ExecFloat.mul b32(0x80000000) b32(0x3f800000)) := by
  decide

/-- Reversing three finite binary32 contributions can change the ordered accumulated result. -/
theorem binary32_reversal_refuted :
    ExecFloat.Binary.toNatBits
      (([b32(0x4b800000), b32(0x3f800000), b32(0xcb800000)]).foldl ExecFloat.add b32(0)) ≠
      ExecFloat.Binary.toNatBits
        (([b32(0xcb800000), b32(0x3f800000), b32(0x4b800000)]).foldl ExecFloat.add b32(0)) := by
  decide

end TensorRewrite.Theory.ConvolutionFloat
