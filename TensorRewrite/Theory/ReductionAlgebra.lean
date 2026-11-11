module

public import Mathlib.Algebra.BigOperators.Group.List.Basic
public import TensorRewrite.Pilot.ReductionRules
public import TensorRewrite.Theory.ReductionFiberLemmas

/-! Reduction identities with explicit initializer, nonemptiness and scalar laws.
Exact additive results do not supply IEEE addition with associative/group structure. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ReductionAlgebra

open Pilot Pilot.Reduction ReductionFiber

/-- A nonempty constant fiber collapses under absorption, retaining the actual initializer. -/
theorem constant_absorb {α : Type} (plan : Plan) (operation : α → α → α)
    (initial value : α) (nonempty : 0 < plan.fiberCount)
    (absorb : ∀ accumulator, operation (operation accumulator value) value =
      operation accumulator value) :
    reduceTensor plan operation initial (Tensor.constant value) =
      Tensor.constant (operation initial value) := by
  funext output
  unfold reduceTensor
  rw [fiberValues_constant]
  exact foldl_replicate_absorb operation value absorb plan.fiberCount nonempty initial

/-- Boolean conjunction of a repeated scalar includes the initializer, for nonempty fibers. -/
theorem constant_and (plan : Plan) (initial value : Bool) (nonempty : 0 < plan.fiberCount) :
    reduceTensor plan Bool.and initial (Tensor.constant value) =
      Tensor.constant (value && initial) := by
  have absorb : ∀ accumulator, (accumulator && value && value) = (accumulator && value) := by
    intro accumulator
    cases accumulator <;> cases value <;> rfl
  rw [constant_absorb plan Bool.and initial value nonempty absorb]
  cases initial <;> cases value <;> rfl

/-- Boolean disjunction of a repeated scalar includes the initializer, for nonempty fibers. -/
theorem constant_or (plan : Plan) (initial value : Bool) (nonempty : 0 < plan.fiberCount) :
    reduceTensor plan Bool.or initial (Tensor.constant value) =
      Tensor.constant (value || initial) := by
  have absorb : ∀ accumulator, (accumulator || value || value) = (accumulator || value) := by
    intro accumulator
    cases accumulator <;> cases value <;> rfl
  rw [constant_absorb plan Bool.or initial value nonempty absorb]
  cases initial <;> cases value <;> rfl

/-- Linear-order minimum is idempotent, without assuming a greatest initializer. -/
theorem constant_min {α : Type} [LinearOrder α] (plan : Plan) (initial value : α)
    (nonempty : 0 < plan.fiberCount) :
    reduceTensor plan min initial (Tensor.constant value) =
      Tensor.constant (min value initial) := by
  rw [constant_absorb plan min initial value nonempty (by intro x; simp)]
  rw [min_comm initial value]

/-- Linear-order maximum is idempotent, without assuming a least initializer. -/
theorem constant_max {α : Type} [LinearOrder α] (plan : Plan) (initial value : α)
    (nonempty : 0 < plan.fiberCount) :
    reduceTensor plan max initial (Tensor.constant value) =
      Tensor.constant (max value initial) := by
  rw [constant_absorb plan max initial value nonempty (by intro x; simp)]
  rw [max_comm initial value]

/-- Exact addition of a constant counts its multiplicity and includes the initializer once. -/
theorem constant_add {α : Type} [AddMonoid α] (plan : Plan) (initial value : α) :
    reduceTensor plan (· + ·) initial (Tensor.constant value) =
      Tensor.constant (initial + plan.fiberCount • value) := by
  funext output
  unfold reduceTensor
  rw [fiberValues_constant, FiniteSum.foldl_add_eq_sum, List.sum_replicate]
  rfl

/-- Negation moves across exact additive reduction with zero initializer. -/
theorem negate_sum {α : Type} [AddCommGroup α] (plan : Plan)
    (input : Tensor plan.inputShape α) :
    reduceTensor plan (· + ·) 0 (Tensor.map Neg.neg input) =
      Tensor.map Neg.neg (reduceTensor plan (· + ·) 0 input) := by
  funext output
  simp only [reduceTensor, Tensor.map, fiberValues_map, FiniteSum.foldl_add_eq_sum, zero_add]
  exact (List.sum_neg _).symm

/-- Contiguous blocks may reduce separately then combine exactly with neutral initializers. -/
theorem concat_add {α : Type} [AddMonoid α] (blocks : List (List α)) :
    blocks.flatten.foldl (· + ·) 0 =
      (blocks.map fun block => block.foldl (· + ·) 0).foldl (· + ·) 0 := by
  simp only [FiniteSum.foldl_add_eq_sum, zero_add, List.sum_flatten]

/-- The original reduction equals its derived bounded-coordinate fiber sum with one initializer. -/
theorem coordinate_sum {α : Type} [AddCommMonoid α] (plan : Plan) (initial : α)
    (input : Tensor plan.inputShape α) (output : Index plan.outputShape) :
    reduceTensor plan (· + ·) initial input output =
      initial + ∑ reduced : Index (ReductionFiber.shape plan),
        input (mergeIndex plan output reduced) := by
  exact (FiniteSum.foldl_add_eq_sum _ initial).trans
    (congrArg (initial + ·) (fiberValues_sum plan input output))

/-- Reducing all remaining axes after an exact zero-initialized reduction counts each input once. -/
theorem sum_reduction {α : Type} [AddCommMonoid α] (plan : Plan)
    (input : Tensor plan.inputShape α) :
    (∑ output, reduceTensor plan (· + ·) 0 input output) = ∑ index, input index := by
  simp_rw [coordinate_sum, zero_add]
  calc
    (∑ output, ∑ reduced, input (mergeIndex plan output reduced)) =
        ∑ pair : Index plan.outputShape × Index (ReductionFiber.shape plan),
          input (mergeIndex plan pair.1 pair.2) :=
      (Fintype.sum_prod_type (fun pair : Index plan.outputShape ×
        Index (ReductionFiber.shape plan) => input (mergeIndex plan pair.1 pair.2))).symm
    _ = _ := Equiv.sum_comp (splitEquiv plan).symm input

/-- A homomorphism moves across reduction with its transformed initializer, preserving order. -/
theorem map_reduction {α β : Type} (plan : Plan) (f : α → β)
    (operation : α → α → α) (target : β → β → β)
    (hom : ∀ a b, target (f a) (f b) = f (operation a b)) (initial : α)
    (input : Tensor plan.inputShape α) :
    reduceTensor plan target (f initial) (Tensor.map f input) =
      Tensor.map f (reduceTensor plan operation initial input) := by
  funext output
  change (fiberValues plan (Tensor.map f input) output).foldl target (f initial) = _
  rw [fiberValues_map]
  exact foldl_map_hom f operation target hom _ initial

/-- Empty inputs return each actual tuple initializer even for a coupled pure reducer. -/
theorem empty_components {components : Type} {α : components → Type} (plan : Plan)
    (operation : ((c : components) → α c) → ((c : components) → α c) →
      ((c : components) → α c)) (initial : (c : components) → α c)
    (input : Tensor plan.inputShape ((c : components) → α c))
    (empty : LinearIndex.elementCount plan.inputShape = 0) (component : components) :
    Tensor.map (fun state => state component) (reduceTensor plan operation initial input) =
      Tensor.constant (initial component) := by
  rw [reduceTensor_empty_input plan operation initial input empty]
  rfl

/-- Equal-count tuple reductions remove unit fibers under the whole-state initializer law. -/
theorem sameCount_components {components : Type} {α : components → Type} (plan : Plan)
    (operation : ((c : components) → α c) → ((c : components) → α c) →
      ((c : components) → α c)) (initial : (c : components) → α c)
    (leftIdentity : ∀ state, operation initial state = state)
    (input : Tensor plan.inputShape ((c : components) → α c))
    (sameCount : LinearIndex.elementCount plan.inputShape =
      LinearIndex.elementCount plan.outputShape) (component : components) :
    Tensor.map (fun state => state component) (reduceTensor plan operation initial input) =
      Reshape.reshapeTensor (Tensor.map (fun state => state component) input)
        plan.outputShape sameCount := by
  rw [reduceTensor_sameCount plan operation initial leftIdentity input sameCount]
  rfl

end TensorRewrite.Theory.ReductionAlgebra
