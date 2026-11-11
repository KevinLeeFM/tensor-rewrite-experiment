import TensorRewrite.Comparisons.FixedTacticsGuard

set_option autoImplicit false

run_cmd TensorRewrite.Comparisons.FixedTactics.noCampaignProofs

namespace TensorRewrite.Theory.FloatNegation
open FloatLib.Floats.Formats.BinaryInterchange

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem scalar_involution {format : FloatFormat} (x : Model format) :
    Model.neg (Model.neg x) = x :=
  Model.neg_neg x

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem tensor_involution {rank : Nat} {shape : Pilot.Shape rank} {format : FloatFormat}
    (x : Pilot.Tensor shape (Model format)) :
    Pilot.Tensor.map Model.neg (Pilot.Tensor.map Model.neg x) = x := by
  funext index
  exact scalar_involution (x index)

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem reindex_neg {inputRank outputRank : Nat}
    {inputShape : Pilot.Shape inputRank} {outputShape : Pilot.Shape outputRank}
    {format : FloatFormat} (indices : Pilot.Index outputShape → Pilot.Index inputShape)
    (x : Pilot.Tensor inputShape (Model format)) :
    Pilot.Tensor.reindex indices (Pilot.Tensor.map Model.neg x) =
      Pilot.Tensor.map Model.neg (Pilot.Tensor.reindex indices x) := rfl

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem reverse_neg {rank : Nat} {shape : Pilot.Shape rank} {format : FloatFormat}
    (axes : Fin rank → Bool) (x : Pilot.Tensor shape (Model format)) :
    Pilot.Tensor.reverse axes (Pilot.Tensor.map Model.neg x) =
      Pilot.Tensor.map Model.neg (Pilot.Tensor.reverse axes x) := rfl

end TensorRewrite.Theory.FloatNegation

namespace TensorRewrite.Theory.FiniteSum
open Pilot
open Pilot.LinearIndex

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem foldl_add_eq_sum {α : Type} [AddMonoid α] (values : List α) (initial : α) :
    values.foldl (· + ·) initial = initial + values.sum := by
  induction values generalizing initial with
  | nil => simp
  | cons value values ih =>
    simp only [List.foldl_cons, List.sum_cons]
    rw [ih, add_assoc]

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem reduce_add_eq_fiber_sum {α : Type} [AddMonoid α] (plan : Reduction.Plan)
    (input : Tensor plan.inputShape α) :
    Reduction.reduceTensor plan (· + ·) 0 input =
      fun output => (Reduction.fiberValues plan input output).sum := by
  funext output
  exact (foldl_add_eq_sum _ 0).trans (zero_add _)

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem sum_swap {α I J : Type} [AddCommMonoid α] [Fintype I] [Fintype J]
    (input : I → J → α) : (∑ i, ∑ j, input i j) = ∑ j, ∑ i, input i j :=
  Finset.sum_comm

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem sum_add {α I : Type} [AddCommMonoid α] [Fintype I] (x y : I → α) :
    (∑ i, x i) + (∑ i, y i) = ∑ i, (x i + y i) :=
  (Finset.sum_add_distrib).symm

end TensorRewrite.Theory.FiniteSum

namespace TensorRewrite.Theory.Convolution

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem inputIndex?_negative (axis : Axis) (output : Nat) (kernel : Fin axis.kernelExtent)
    (negative : axis.basePosition output kernel < 0) :
    axis.inputIndex? output kernel = none := by
  simp [Axis.inputIndex?, not_le.mpr negative]

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem basePosition_reverse (axis : Axis) (output : Nat) (kernel : Fin axis.kernelExtent) :
    Axis.basePosition { axis with reversed := !axis.reversed } output kernel.rev =
      axis.basePosition output kernel := by
  cases reversed : axis.reversed <;> simp [Axis.basePosition, reversed]

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem inputIndex?_position (axis : Axis) (output : Nat) (kernel : Fin axis.kernelExtent)
    (index : Fin axis.inputExtent) (sample : axis.inputIndex? output kernel = some index) :
    (index.val : Int) * axis.baseDilation = axis.basePosition output kernel := by
  unfold Axis.inputIndex? at sample
  dsimp only at sample
  split at sample
  next valid =>
    have values := congrArg Fin.val (Option.some.inj sample)
    dsimp only at values
    have nonnegative : 0 ≤ axis.basePosition output kernel / (axis.baseDilation : Int) :=
      Int.ediv_nonneg valid.1 (by have := axis.baseDilation_pos; omega)
    have cast : (index.val : Int) = axis.basePosition output kernel / axis.baseDilation := by
      have castValues : ((axis.basePosition output kernel / axis.baseDilation).toNat : Int) =
          (index.val : Int) := congrArg (fun value : Nat => (value : Int)) values
      rw [Int.toNat_of_nonneg nonnegative] at castValues
      exact castValues.symm
    rw [cast]
    simpa only [valid.2.1, add_zero] using
      Int.ediv_mul_add_emod (axis.basePosition output kernel) (axis.baseDilation : Int)
  next invalid => contradiction

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem term_zero_kernel {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape)) :
    term plan input (fun _ _ _ _ _ => 0) output position = 0 := by
  dsimp only [term]
  split <;> simp

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem term_zero_input {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (kernel : Kernel plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape)) :
    term plan (fun _ _ _ => 0) kernel output position = 0 := by
  dsimp only [term]
  split <;> simp

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem convolve_zero_kernel {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) : convolve plan input (fun _ _ _ _ _ => 0) = fun _ => 0 := by
  funext output
  change (List.map (term plan input (fun _ _ _ _ _ => 0) output) _).sum = 0
  rw [show term plan input (fun _ _ _ _ _ => (0 : α)) output = fun _ => 0 by
    funext position; exact term_zero_kernel plan input output position]
  simp

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem convolve_zero_input {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (kernel : Kernel plan α) : convolve plan (fun _ _ _ => 0) kernel = fun _ => 0 := by
  funext output
  change (List.map (term plan (fun _ _ _ => 0) kernel output) _).sum = 0
  rw [show term plan (fun _ _ _ => (0 : α)) kernel output = fun _ => 0 by
    funext position; exact term_zero_input plan kernel output position]
  simp

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem convolve_empty_fiber {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α)
    (empty : plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape = 0) :
    convolve plan input kernel = fun _ => 0 := by
  funext output
  have noPositions : List.finRange
      (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape) = [] :=
    List.eq_nil_of_length_eq_zero (List.length_finRange.trans empty)
  change (List.map (term plan input kernel output) _).sum = 0
  rw [noPositions]
  rfl

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem spatialInput?_empty {rank : Nat} (plan : Plan rank)
    (empty : Pilot.LinearIndex.elementCount plan.inputShape = 0)
    (output : Pilot.Index plan.outputShape) (kernel : Pilot.Index plan.kernelShape) :
    spatialInput? plan output kernel = none := by
  cases sample : spatialInput? plan output kernel with
  | none => rfl
  | some coordinates =>
    have bound := (Pilot.LinearIndex.linearize plan.inputShape coordinates).isLt
    omega

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem term_empty_spatial_input {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape))
    (empty : Pilot.LinearIndex.elementCount plan.inputShape = 0) :
    term plan input kernel output position = 0 := by
  dsimp only [term]
  rw [spatialInput?_empty plan empty]

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem convolve_empty_spatial_input {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α)
    (empty : Pilot.LinearIndex.elementCount plan.inputShape = 0) :
    convolve plan input kernel = fun _ => 0 := by
  funext output
  change (List.map (term plan input kernel output) _).sum = 0
  rw [show term plan input kernel output = fun _ => (0 : α) by
    funext position; exact term_empty_spatial_input plan input kernel output position empty]
  simp

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem convolve_empty_kernel {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α)
    (empty : Pilot.LinearIndex.elementCount plan.kernelShape = 0) :
    convolve plan input kernel = fun _ => 0 :=
  convolve_empty_fiber plan input kernel (by rw [empty, Nat.mul_zero])

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem convolve_no_channels {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (kernel : Kernel plan α) (empty : plan.inputFeaturesPerGroup = 0) :
    convolve plan input kernel = fun _ => 0 :=
  convolve_empty_fiber plan input kernel (by rw [empty, Nat.zero_mul])

end TensorRewrite.Theory.Convolution

namespace TensorRewrite.Theory.Convolution

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem term_kernel_add {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (input : Input plan α) (f g : Kernel plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape)) :
    term plan input (fun b h o c s => f b h o c s + g b h o c s) output position =
      term plan input f output position + term plan input g output position := by
  dsimp only [term]
  split <;> simp [mul_add]

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem term_input_add {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (x y : Input plan α) (kernel : Kernel plan α) (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * Pilot.LinearIndex.elementCount plan.kernelShape)) :
    term plan (fun b c s => x b c s + y b c s) kernel output position =
      term plan x kernel output position + term plan y kernel output position := by
  dsimp only [term]
  split <;> simp [add_mul]

/-- Historical agent proof replay, with unchanged reviewed statement. -/
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

/-- Historical agent proof replay, with unchanged reviewed statement. -/
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

/-- Historical agent proof replay, with unchanged reviewed statement. -/
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

/-- Historical agent proof replay, with unchanged reviewed statement. -/
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

/-- Historical agent proof replay, with unchanged reviewed statement. -/
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

namespace TensorRewrite.Theory.ConvolutionPointwise
open Pilot
open Convolution

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem dilatedExtent_one (extent : Nat) : dilatedExtent extent 1 = extent := by
  unfold dilatedExtent
  split <;> omega

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem output_extent_eq (axis : Axis) (pointwise : IsPointwiseAxis axis) :
    axis.outputExtent = axis.inputExtent := by
  unfold Axis.outputExtent
  rw [pointwise.unitKernel, pointwise.unitStride, pointwise.unitBaseDilation,
    pointwise.noLowPadding, pointwise.noHighPadding, dilatedExtent_one]
  simp [dilatedExtent]

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem output_shape_eq {rank : Nat} (plan : Plan rank) (pointwise : IsPointwise plan) :
    plan.outputShape = plan.inputShape := by
  funext axis
  exact output_extent_eq (plan.window axis) (pointwise axis)

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem elementCount_unit {rank : Nat} (shape : Shape rank) (unit : ∀ axis, shape axis = 1) :
    LinearIndex.elementCount shape = 1 := by
  induction rank with
  | zero => rfl
  | succ rank ih =>
    simp only [LinearIndex.elementCount]
    rw [unit, ih _ (fun axis => unit axis.succ), Nat.one_mul]

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem kernel_count_eq_one {rank : Nat} (plan : Plan rank) (pointwise : IsPointwise plan) :
    LinearIndex.elementCount plan.kernelShape = 1 :=
  elementCount_unit plan.kernelShape (fun axis => (pointwise axis).unitKernel)

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem kernel_index_unique {rank : Nat} (plan : Plan rank)
    (unitKernel : ∀ axis, plan.kernelShape axis = 1) (index : Index plan.kernelShape) :
    index = kernelIndex plan unitKernel := by
  funext axis
  apply Fin.ext
  have bound := (index axis).isLt
  have unit := unitKernel axis
  change (index axis).val = 0
  omega

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem base_position_eq (axis : Axis) (pointwise : IsPointwiseAxis axis)
    (output : Nat) (kernel : Fin axis.kernelExtent) :
    axis.basePosition output kernel = output := by
  have unit := pointwise.unitKernel
  have value : kernel.val = 0 := by have := kernel.isLt; omega
  simp [Axis.basePosition, pointwise.unitStride, pointwise.noLowPadding, unit, value]

end TensorRewrite.Theory.ConvolutionPointwise

namespace TensorRewrite.Theory.ConvolutionPointwise
open Pilot
open Convolution

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem sum_kernel_positions {rank : Nat} {α : Type} [AddCommMonoid α] (plan : Plan rank)
    (pointwise : IsPointwise plan) (value : Fin plan.inputFeaturesPerGroup → α) :
    (∑ position : Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape),
      value (FiniteProduct.row position)) = ∑ channel, value channel := by
  let equivalence :
      Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape) ≃
        Fin plan.inputFeaturesPerGroup :=
    finCongr (by rw [kernel_count_eq_one plan pointwise, Nat.mul_one])
  have row_eq (position :
      Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape)) :
      FiniteProduct.row position = equivalence position := by
    apply Fin.ext
    simp [FiniteProduct.row, equivalence, kernel_count_eq_one plan pointwise]
  calc
    _ = ∑ position, value (equivalence position) := by
      apply Finset.sum_congr rfl
      intro position _
      rw [row_eq]
    _ = _ := Equiv.sum_comp equivalence value

end TensorRewrite.Theory.ConvolutionPointwise

namespace TensorRewrite.Theory.LogicalFamily
open Pilot

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem rewrite_sound {domain : Domain} {rank : Nat} {shape : Shape rank}
    (rule : Rule domain) (inputs : Nat → Tensor shape domain.Value)
    (condition : rule.Condition inputs) : rule.lhs.eval inputs = rule.rhs.eval inputs := by
  cases domain with
  | predicate =>
    cases rule <;> funext index <;>
      simp_all [Rule.Condition, Rule.lhs, Rule.rhs, Expr.eval, Tensor.map, Tensor.map₂,
        Tensor.constant, Domain.not, Domain.and, Domain.or, Domain.xor, Domain.zero]
  | word width =>
    cases rule <;> funext index <;>
      simp_all [Rule.Condition, Rule.lhs, Rule.rhs, Expr.eval, Tensor.map, Tensor.map₂,
        Tensor.constant, Domain.not, Domain.and, Domain.or, Domain.xor, Domain.zero]

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem allRules_complete {domain : Domain} (rule : Rule domain) : rule ∈ allRules domain := by
  cases domain <;> cases rule <;> simp [allRules]

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem allRules_nodup (domain : Domain) : (allRules domain).Nodup := by
  cases domain <;> simp [allRules]

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem word_keys_uniform (width : Nat) :
    (allRules (.word width)).map Rule.key = (allRules (.word 0)).map Rule.key := rfl

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem predicate_count : (allRules .predicate).length = 12 := rfl

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem word_count (width : Nat) : (allRules (.word width)).length = 8 := rfl

end TensorRewrite.Theory.LogicalFamily

namespace TensorRewrite.Theory.ContractionAlgebra
open Pilot
open Pilot.Contraction

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem dot_add_left {α : Type} [Semiring α] {batch left right contracting : Nat}
    (plan : Plan batch left right contracting)
    (x y : Tensor plan.lhsShape α) (z : Tensor plan.rhsShape α) :
    dotTensor plan (· + ·) 0 (· * ·) id (Tensor.map₂ (· + ·) x y) z =
      Tensor.map₂ (· + ·) (dotTensor plan (· + ·) 0 (· * ·) id x z)
        (dotTensor plan (· + ·) 0 (· * ·) id y z) := by
  funext output
  simp only [dotTensor, terms, Tensor.map₂, id_eq,
    FiniteSum.foldl_add_eq_sum, zero_add, add_mul]
  exact List.sum_map_add

/-- Historical agent proof replay, with unchanged reviewed statement. -/
theorem dot_add_right {α : Type} [Semiring α] {batch left right contracting : Nat}
    (plan : Plan batch left right contracting)
    (x : Tensor plan.lhsShape α) (y z : Tensor plan.rhsShape α) :
    dotTensor plan (· + ·) 0 (· * ·) id x (Tensor.map₂ (· + ·) y z) =
      Tensor.map₂ (· + ·) (dotTensor plan (· + ·) 0 (· * ·) id x y)
        (dotTensor plan (· + ·) 0 (· * ·) id x z) := by
  funext output
  simp only [dotTensor, terms, Tensor.map₂, id_eq,
    FiniteSum.foldl_add_eq_sum, zero_add, mul_add]
  exact List.sum_map_add

end TensorRewrite.Theory.ContractionAlgebra

run_cmd TensorRewrite.Comparisons.FixedTactics.allStatements

#print axioms TensorRewrite.Theory.FloatNegation.scalar_involution
#print axioms TensorRewrite.Theory.FloatNegation.tensor_involution
#print axioms TensorRewrite.Theory.FloatNegation.reindex_neg
#print axioms TensorRewrite.Theory.FloatNegation.reverse_neg
#print axioms TensorRewrite.Theory.FiniteSum.foldl_add_eq_sum
#print axioms TensorRewrite.Theory.FiniteSum.reduce_add_eq_fiber_sum
#print axioms TensorRewrite.Theory.FiniteSum.sum_swap
#print axioms TensorRewrite.Theory.FiniteSum.sum_add
#print axioms TensorRewrite.Theory.Convolution.inputIndex?_negative
#print axioms TensorRewrite.Theory.Convolution.basePosition_reverse
#print axioms TensorRewrite.Theory.Convolution.inputIndex?_position
#print axioms TensorRewrite.Theory.Convolution.term_zero_kernel
#print axioms TensorRewrite.Theory.Convolution.term_zero_input
#print axioms TensorRewrite.Theory.Convolution.convolve_zero_kernel
#print axioms TensorRewrite.Theory.Convolution.convolve_zero_input
#print axioms TensorRewrite.Theory.Convolution.convolve_empty_fiber
#print axioms TensorRewrite.Theory.Convolution.spatialInput?_empty
#print axioms TensorRewrite.Theory.Convolution.term_empty_spatial_input
#print axioms TensorRewrite.Theory.Convolution.convolve_empty_spatial_input
#print axioms TensorRewrite.Theory.Convolution.convolve_empty_kernel
#print axioms TensorRewrite.Theory.Convolution.convolve_no_channels
#print axioms TensorRewrite.Theory.Convolution.term_kernel_add
#print axioms TensorRewrite.Theory.Convolution.term_input_add
#print axioms TensorRewrite.Theory.Convolution.term_kernel_scale
#print axioms TensorRewrite.Theory.Convolution.convolve_kernel_add
#print axioms TensorRewrite.Theory.Convolution.convolve_input_add
#print axioms TensorRewrite.Theory.Convolution.convolve_kernel_scale
#print axioms TensorRewrite.Theory.Convolution.convolve_bias_scale
#print axioms TensorRewrite.Theory.ConvolutionPointwise.dilatedExtent_one
#print axioms TensorRewrite.Theory.ConvolutionPointwise.output_extent_eq
#print axioms TensorRewrite.Theory.ConvolutionPointwise.output_shape_eq
#print axioms TensorRewrite.Theory.ConvolutionPointwise.elementCount_unit
#print axioms TensorRewrite.Theory.ConvolutionPointwise.kernel_count_eq_one
#print axioms TensorRewrite.Theory.ConvolutionPointwise.kernel_index_unique
#print axioms TensorRewrite.Theory.ConvolutionPointwise.base_position_eq
#print axioms TensorRewrite.Theory.ConvolutionPointwise.sum_kernel_positions
#print axioms TensorRewrite.Theory.LogicalFamily.rewrite_sound
#print axioms TensorRewrite.Theory.LogicalFamily.allRules_complete
#print axioms TensorRewrite.Theory.LogicalFamily.allRules_nodup
#print axioms TensorRewrite.Theory.LogicalFamily.word_keys_uniform
#print axioms TensorRewrite.Theory.LogicalFamily.predicate_count
#print axioms TensorRewrite.Theory.LogicalFamily.word_count
#print axioms TensorRewrite.Theory.ContractionAlgebra.dot_add_left
#print axioms TensorRewrite.Theory.ContractionAlgebra.dot_add_right
