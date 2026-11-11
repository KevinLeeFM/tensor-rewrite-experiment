module

public import TensorRewrite.Theory.ReductionWindowLemmas
public import TensorRewrite.Pilot.ReshapeLemmas

/-! Window-to-pointwise transformations with explicit padding and initializer laws. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ReductionWindow

open Pilot

/-- A window without kernel coordinates performs no updates, regardless of its input. -/
theorem reduce_empty_kernel {rank : Nat} {α : Type} (plan : Plan rank)
    (operation : α → α → α) (initial padding : α) (input : Tensor plan.inputShape α)
    (empty : LinearIndex.elementCount plan.kernelShape = 0) :
    reduce plan operation initial padding input = Tensor.constant initial := by
  funext output
  have noPositions : List.finRange (LinearIndex.elementCount plan.kernelShape) = [] :=
    List.eq_nil_of_length_eq_zero (List.length_finRange.trans empty)
  simp only [reduce, values, Tensor.constant]
  rw [noPositions]
  rfl

/-- Empty input still folds every padding sample; this does not silently return the initializer. -/
theorem reduce_empty_input {rank : Nat} {α : Type} (plan : Plan rank)
    (operation : α → α → α) (initial padding : α) (input : Tensor plan.inputShape α)
    (empty : LinearIndex.elementCount plan.inputShape = 0) :
    reduce plan operation initial padding input = Tensor.constant
      ((List.replicate (LinearIndex.elementCount plan.kernelShape) padding).foldl
        operation initial) := by
  funext output
  exact congrArg (fun samples => samples.foldl operation initial)
    (values_empty_input plan padding input empty output)

/-- Initializer-valued padding over empty input collapses only under its stated fixed-point law. -/
theorem reduce_empty_input_fixed {rank : Nat} {α : Type} (plan : Plan rank)
    (operation : α → α → α) (initial : α) (input : Tensor plan.inputShape α)
    (empty : LinearIndex.elementCount plan.inputShape = 0)
    (fixed : operation initial initial = initial) :
    reduce plan operation initial initial input = Tensor.constant initial := by
  rw [reduce_empty_input plan operation initial initial input empty]
  rw [foldl_replicate_fixed operation initial initial fixed]

/-- Empty output has no observation, independently of every scalar/padding law. -/
theorem reduce_empty_output {rank : Nat} {α : Type} (plan : Plan rank)
    (operation : α → α → α) (initial padding : α) (input : Tensor plan.inputShape α)
    (empty : LinearIndex.elementCount plan.outputShape = 0) :
    reduce plan operation initial padding input = Tensor.constant initial :=
  Reshape.tensor_eq_of_empty empty _ _

/-- A unit window performs exactly one operation with the actual initializer. -/
theorem reduce_unit {rank : Nat} {α : Type} (plan : Plan rank) (unit : IsUnit plan)
    (operation : α → α → α) (initial padding : α) (input : Tensor plan.inputShape α) :
    reduce plan operation initial padding input = fun output =>
      operation initial (contribution plan padding input output (unitIndex plan unit)) := by
  funext output
  unfold reduce
  rw [values_unit plan unit]
  rfl

/-- Unit undilated windows become an independent crop/stride gather and pointwise map. -/
theorem unit_gather {rank : Nat} {α : Type} (plan : Plan rank) (unit : IsUnit plan)
    (undilated : IsUndilated plan) (operation : α → α → α) (initial padding : α)
    (paddingFixed : operation initial padding = padding) (input : Tensor plan.inputShape α) :
    reduce plan operation initial padding input =
      gatherMap plan padding (operation initial) input := by
  rw [reduce_unit plan unit]
  funext output
  simp only [contribution, sample_unit_affine plan unit undilated, gatherMap]
  cases affineInput? plan output <;> simp [paddingFixed]

/-- The common initializer-as-padding profile keeps its explicit idempotence condition. -/
theorem unit_gather_initial {rank : Nat} {α : Type} (plan : Plan rank) (unit : IsUnit plan)
    (undilated : IsUndilated plan) (operation : α → α → α) (initial : α)
    (fixed : operation initial initial = initial) (input : Tensor plan.inputShape α) :
    reduce plan operation initial initial input =
      gatherMap plan initial (operation initial) input :=
  unit_gather plan unit undilated operation initial initial fixed input

/-- Neutral exact addition requires no reassociation for a unit-window crop/stride gather. -/
theorem unit_gather_add_zero {rank : Nat} {α : Type} [AddZeroClass α] (plan : Plan rank)
    (unit : IsUnit plan) (undilated : IsUndilated plan) (input : Tensor plan.inputShape α) :
    reduce plan (· + ·) 0 0 input = gatherMap plan 0 id input := by
  have neutral : (fun x : α => (0 : α) + x) = id := by funext x; exact zero_add x
  simpa only [neutral] using
    unit_gather plan unit undilated (· + ·) (0 : α) 0 (by simp) input

/-- Linear-order minimum is pointwise min with the initializer, followed by its padding fill. -/
theorem unit_gather_min {rank : Nat} {α : Type} [LinearOrder α] (plan : Plan rank)
    (unit : IsUnit plan) (undilated : IsUndilated plan) (initial : α)
    (input : Tensor plan.inputShape α) :
    reduce plan min initial initial input =
      gatherMap plan initial (fun x => min x initial) input := by
  have same : min initial = fun x => min x initial := by funext x; exact min_comm _ _
  simpa only [same] using unit_gather_initial plan unit undilated min initial (min_self _) input

/-- Linear-order maximum likewise retains the initializer and fills invalid positions. -/
theorem unit_gather_max {rank : Nat} {α : Type} [LinearOrder α] (plan : Plan rank)
    (unit : IsUnit plan) (undilated : IsUndilated plan) (initial : α)
    (input : Tensor plan.inputShape α) :
    reduce plan max initial initial input =
      gatherMap plan initial (fun x => max x initial) input := by
  have same : max initial = fun x => max x initial := by funext x; exact max_comm _ _
  simpa only [same] using unit_gather_initial plan unit undilated max initial (max_self _) input

/-- Pointwise geometry samples its unique valid input and retains one initialized operation. -/
theorem pointwise {rank : Nat} {α : Type} (plan : Plan rank)
    (geometry : ConvolutionPointwise.IsPointwise plan.asConvolution)
    (operation : α → α → α) (initial padding : α) (input : Tensor plan.inputShape α) :
    reduce plan operation initial padding input = fun output => operation initial
      (input (ConvolutionPointwise.inputIndex plan.asConvolution
        (ConvolutionPointwise.output_shape_eq plan.asConvolution geometry) output)) := by
  rw [reduce_unit plan (fun axis => (geometry axis).unitKernel)]
  funext output
  unfold contribution
  have sampled := ConvolutionPointwise.spatial_input_eq plan.asConvolution geometry
    output (unitIndex plan (fun axis => (geometry axis).unitKernel))
  change sample? plan output (unitIndex plan _) = _ at sampled
  rw [sampled]

/-- Eliminating a pointwise window needs its whole-state initializer to act identically. -/
theorem pointwise_eliminate {rank : Nat} {α : Type} (plan : Plan rank)
    (geometry : ConvolutionPointwise.IsPointwise plan.asConvolution)
    (operation : α → α → α) (initial padding : α) (input : Tensor plan.inputShape α)
    (identity : ∀ x, operation initial x = x) :
    reduce plan operation initial padding input = fun output =>
      input (ConvolutionPointwise.inputIndex plan.asConvolution
        (ConvolutionPointwise.output_shape_eq plan.asConvolution geometry) output) := by
  rw [pointwise plan geometry]
  funext output
  exact identity _

/-- An explicit outside-axis witness at every output proves the all-cropped broadcast case. -/
theorem unit_crop_all {rank : Nat} {α : Type} (plan : Plan rank) (unit : IsUnit plan)
    (undilated : IsUndilated plan) (operation : α → α → α) (initial padding : α)
    (paddingFixed : operation initial padding = padding) (input : Tensor plan.inputShape α)
    (outside : ∀ output, ∃ axis, affinePosition plan output axis < 0 ∨
      ((plan.window axis).inputExtent : Int) ≤ affinePosition plan output axis) :
    reduce plan operation initial padding input = Tensor.constant padding := by
  rw [unit_gather plan unit undilated operation initial padding paddingFixed]
  funext output
  obtain ⟨axis, invalid⟩ := outside output
  simp [gatherMap, affine_none_of_axis plan output axis invalid, Tensor.constant]

/-- Cropping at least an entire axis from the low side leaves no observed input sample. -/
theorem unit_crop_low_all {rank : Nat} {α : Type} (plan : Plan rank) (unit : IsUnit plan)
    (undilated : IsUndilated plan) (operation : α → α → α) (initial padding : α)
    (paddingFixed : operation initial padding = padding) (input : Tensor plan.inputShape α)
    (axis : Fin rank)
    (crop : (plan.window axis).paddingLow ≤ -((plan.window axis).inputExtent : Int)) :
    reduce plan operation initial padding input = Tensor.constant padding := by
  apply unit_crop_all plan unit undilated operation initial padding paddingFixed input
  intro output
  refine ⟨axis, Or.inr ?_⟩
  have nonnegative : (0 : Int) ≤ ((output axis).val : Int) * (plan.window axis).stride := by
    apply Int.mul_nonneg <;> omega
  unfold affinePosition
  omega

/-- Empty-input tuple windows return each initializer component under the whole-state law. -/
theorem empty_input_components {rank : Nat} {components : Type} {α : components → Type}
    (plan : Plan rank)
    (operation : ((c : components) → α c) → ((c : components) → α c) →
      ((c : components) → α c)) (initial : (c : components) → α c)
    (input : Tensor plan.inputShape ((c : components) → α c))
    (empty : LinearIndex.elementCount plan.inputShape = 0)
    (fixed : operation initial initial = initial) (component : components) :
    Tensor.map (fun state => state component) (reduce plan operation initial initial input) =
      Tensor.constant (initial component) := by
  rw [reduce_empty_input_fixed plan operation initial input empty fixed]
  rfl

end TensorRewrite.Theory.ReductionWindow
