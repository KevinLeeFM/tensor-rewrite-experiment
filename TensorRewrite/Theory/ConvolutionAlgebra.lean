module

public import TensorRewrite.Theory.ConvolutionLemmas

/-! Exact convolution linearity and per-output-feature scaling over a semiring.
Multiplication need not commute. All results use the derived window sampling model. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Convolution

/-- Kernel addition distributes in every masked contribution. -/
theorem term_kernel_add {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (f g : Kernel plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape)) :
    term plan input (fun b h o c s => f b h o c s + g b h o c s) output position =
      term plan input f output position + term plan input g output position := by
  dsimp only [term]
  split <;> simp [mul_add]

/-- Input addition distributes in every masked contribution. -/
theorem term_input_add {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (x y : Input plan α) (kernel : Kernel plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape)) :
    term plan (fun b c s => x b c s + y b c s) kernel output position =
      term plan x kernel output position + term plan y kernel output position := by
  dsimp only [term]
  split <;> simp [add_mul]

/-- A right factor constant on an output feature moves through each masked contribution. -/
theorem term_kernel_scale {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α)
    (weights : Fin plan.batchGroups → Fin plan.featureGroups → Fin plan.outputFeaturesPerGroup → α)
    (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape)) :
    term plan input (fun b h o c s => kernel b h o c s * weights b h o)
      output position =
      term plan input kernel output position *
        weights output.batchGroup output.featureGroup output.feature := by
  dsimp only [term]
  split <;> simp [mul_assoc]

/-- Convolution distributes over the kernel for every grouping and window geometry. -/
theorem convolve_kernel_add {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (f g : Kernel plan α) :
    convolve plan input (fun b h o c s => f b h o c s + g b h o c s) =
      fun output => convolve plan input f output + convolve plan input g output := by
  funext output
  change (List.map (term plan input (fun b h o c s => f b h o c s + g b h o c s) output) _).sum =
    (List.map (term plan input f output) _).sum + (List.map (term plan input g output) _).sum
  rw [show term plan input (fun b h o c s => f b h o c s + g b h o c s) output =
      fun position => term plan input f output position + term plan input g output position by
    funext position; exact term_kernel_add plan input f g output position]
  exact List.sum_map_add

/-- Convolution distributes over its input tensor in the same exact semiring model. -/
theorem convolve_input_add {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (x y : Input plan α) (kernel : Kernel plan α) :
    convolve plan (fun b c s => x b c s + y b c s) kernel =
      fun output => convolve plan x kernel output + convolve plan y kernel output := by
  funext output
  change (List.map (term plan (fun b c s => x b c s + y b c s) kernel output) _).sum =
    (List.map (term plan x kernel output) _).sum + (List.map (term plan y kernel output) _).sum
  rw [show term plan (fun b c s => x b c s + y b c s) kernel output =
      fun position => term plan x kernel output position + term plan y kernel output position by
    funext position; exact term_input_add plan x y kernel output position]
  exact List.sum_map_add

/-- Output-feature scaling can be applied inside the kernel before exact convolution. -/
theorem convolve_kernel_scale {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α)
    (weights :
      Fin plan.batchGroups → Fin plan.featureGroups → Fin plan.outputFeaturesPerGroup → α) :
    convolve plan input (fun b h o c s => kernel b h o c s * weights b h o) =
      fun output => convolve plan input kernel output *
        weights output.batchGroup output.featureGroup output.feature := by
  funext output
  change (List.map
      (term plan input (fun b h o c s => kernel b h o c s * weights b h o) output) _).sum =
    (List.map (term plan input kernel output) _).sum *
      weights output.batchGroup output.featureGroup output.feature
  rw [show term plan input (fun b h o c s => kernel b h o c s * weights b h o) output =
      fun position => term plan input kernel output position *
        weights output.batchGroup output.featureGroup output.feature by
    funext position; exact term_kernel_scale plan input kernel weights output position]
  exact List.sum_map_mul_right _ _ _

/-- Scaling an exact biased convolution moves into the kernel and bias simultaneously. -/
theorem convolve_bias_scale {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α) (bias : OutputIndex plan → α)
    (weights : Fin plan.batchGroups → Fin plan.featureGroups → Fin plan.outputFeaturesPerGroup → α)
    (output : OutputIndex plan) :
    (convolve plan input kernel output + bias output) *
        weights output.batchGroup output.featureGroup output.feature =
      convolve plan input (fun b h o c s => kernel b h o c s * weights b h o) output +
        bias output * weights output.batchGroup output.featureGroup output.feature := by
  rw [convolve_kernel_scale]
  exact add_mul _ _ _

end TensorRewrite.Theory.Convolution
