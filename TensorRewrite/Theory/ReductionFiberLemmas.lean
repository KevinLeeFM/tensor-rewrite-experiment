module

public import Mathlib.Data.Fintype.BigOperators
public import Mathlib.Algebra.BigOperators.Fin
public import TensorRewrite.Theory.ReductionFiber

/-! Reduction coordinate inverses and order-preserving maps of logical fibers. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ReductionFiber

open Pilot Pilot.Reduction

/-- The reduced shape has exactly the previously specified fiber count, including zero. -/
theorem elementCount_shape (plan : Plan) :
    LinearIndex.elementCount (shape plan) = plan.fiberCount := by
  induction plan with
  | scalar => rfl
  | keep extent tail ih => exact ih
  | reduce extent tail ih =>
    change extent * LinearIndex.elementCount (shape tail) = extent * tail.fiberCount
    rw [ih]

/-- Kept-coordinate projection is a left inverse of coordinate merging. -/
theorem output_merge (plan : Plan) (output : Index plan.outputShape)
    (reduced : Index (shape plan)) :
    outputIndex plan (mergeIndex plan output reduced) = output := by
  induction plan with
  | scalar => funext axis; exact Fin.elim0 axis
  | keep extent tail ih =>
    funext axis
    refine Fin.cases rfl (fun axis => ?_) axis
    exact congrFun (ih (fun axis => output axis.succ) reduced) axis
  | reduce extent tail ih => exact ih output (fun axis => reduced axis.succ)

/-- Reduced-coordinate projection is a left inverse of coordinate merging. -/
theorem reduced_merge (plan : Plan) (output : Index plan.outputShape)
    (reduced : Index (shape plan)) :
    reducedIndex plan (mergeIndex plan output reduced) = reduced := by
  induction plan with
  | scalar => funext axis; exact Fin.elim0 axis
  | keep extent tail ih => exact ih (fun axis => output axis.succ) reduced
  | reduce extent tail ih =>
    funext axis
    refine Fin.cases rfl (fun axis => ?_) axis
    exact congrFun (ih output (fun axis => reduced axis.succ)) axis

/-- Splitting an input into its kept/reduced coordinates loses no information. -/
theorem merge_split (plan : Plan) (input : Index plan.inputShape) :
    mergeIndex plan (outputIndex plan input) (reducedIndex plan input) = input := by
  induction plan with
  | scalar => funext axis; exact Fin.elim0 axis
  | keep extent tail ih =>
    funext axis
    refine Fin.cases rfl (fun axis => ?_) axis
    exact congrFun (ih (fun axis => input axis.succ)) axis
  | reduce extent tail ih =>
    funext axis
    refine Fin.cases rfl (fun axis => ?_) axis
    exact congrFun (ih (fun axis => input axis.succ)) axis

/-- A reduction plan decomposes all bounded input coordinates, without a nonempty premise. -/
@[expose] def splitEquiv (plan : Plan) :
    Index plan.inputShape ≃ Index plan.outputShape × Index (shape plan) where
  toFun input := (outputIndex plan input, reducedIndex plan input)
  invFun pair := mergeIndex plan pair.1 pair.2
  left_inv := merge_split plan
  right_inv pair := Prod.ext (output_merge plan pair.1 pair.2) (reduced_merge plan pair.1 pair.2)

/-- A scalar map preserves the order and multiplicity of every reduction fiber. -/
theorem fiberValues_map {α β : Type} (plan : Plan) (f : α → β)
    (input : Tensor plan.inputShape α) (output : Index plan.outputShape) :
    fiberValues plan (Tensor.map f input) output = (fiberValues plan input output).map f := by
  induction plan with
  | scalar => rfl
  | keep extent tail ih => exact ih _ _
  | reduce extent tail ih =>
    simp only [fiberValues, Tensor.map, List.map_flatMap]
    congr 1
    funext coordinate
    exact ih _ _

/-- A uniform input enumerates the value exactly once per admitted fiber element. -/
theorem fiberValues_constant {α : Type} (plan : Plan) (value : α)
    (output : Index plan.outputShape) :
    fiberValues plan (Tensor.constant value) output = List.replicate plan.fiberCount value := by
  have mapped := fiberValues_map plan (fun (_ : Unit) => value) (Tensor.constant ()) output
  change fiberValues plan (Tensor.constant value) output = _ at mapped
  rw [List.map_const', fiberValues_length] at mapped
  exact mapped

/-- A repeated value stabilizes after its first update under the stated absorption law. -/
theorem foldl_replicate_absorb {α : Type} (operation : α → α → α) (value : α)
    (absorb : ∀ initial, operation (operation initial value) value = operation initial value)
    (count : Nat) (nonempty : 0 < count) (initial : α) :
    (List.replicate count value).foldl operation initial = operation initial value := by
  cases count with
  | zero => omega
  | succ count =>
    induction count generalizing initial with
    | zero => rfl
    | succ count ih =>
      rw [List.replicate_succ, List.foldl_cons, ih _ (by omega), absorb]

/-- Split the first bounded coordinate from the remaining axes. -/
@[expose] def headTailEquiv {tailRank : Nat} (extent : Nat) (tailShape : Shape tailRank) :
    Index (Fin.cases extent tailShape) ≃ Fin extent × Index tailShape where
  toFun index := (index ⟨0, Nat.zero_lt_succ _⟩, fun axis => index axis.succ)
  invFun pair := Fin.cases pair.1 pair.2
  left_inv index := by
    funext axis
    exact Fin.cases rfl (fun _ => rfl) axis
  right_inv pair := rfl

/-- Exact sums over a shape decompose over its first coordinate, including zero extents. -/
theorem sum_head_tail {α : Type} [AddCommMonoid α] {tailRank : Nat}
    (extent : Nat) (tailShape : Shape tailRank)
    (input : Tensor (Fin.cases extent tailShape) α) :
    (∑ index, input index) = ∑ head : Fin extent, ∑ tail : Index tailShape,
      input ((headTailEquiv extent tailShape).symm (head, tail)) := by
  calc
    (∑ index, input index) = ∑ pair : Fin extent × Index tailShape,
        input ((headTailEquiv extent tailShape).symm pair) :=
      (Equiv.sum_comp (headTailEquiv extent tailShape).symm input).symm
    _ = _ := Fintype.sum_prod_type _

/-- Summing an ordered flat-map preserves the order of block sums. -/
theorem sum_flatMap {α β : Type} [AddMonoid β] (values : List α) (blocks : α → List β) :
    (values.flatMap blocks).sum = (values.map fun value => (blocks value).sum).sum := by
  induction values with
  | nil => rfl
  | cons value values ih => simp only [List.flatMap_cons, List.sum_append,
      List.map_cons, List.sum_cons, ih]

/-- The actual ordered reduction fiber is an exact sum over the derived reduced coordinates. -/
theorem fiberValues_sum {α : Type} [AddCommMonoid α] (plan : Plan)
    (input : Tensor plan.inputShape α) (output : Index plan.outputShape) :
    (fiberValues plan input output).sum =
      ∑ reduced : Index (shape plan), input (mergeIndex plan output reduced) := by
  induction plan with
  | scalar =>
    have card : Fintype.card (Index (shape Plan.scalar)) = 1 := by
      exact (Fintype.card_congr (FiniteSum.indexEquiv _)).trans (by rfl)
    simp only [fiberValues, List.sum_singleton, mergeIndex]
    simp only [Finset.sum_const, Finset.card_univ, card, one_nsmul]
  | keep extent tail ih => exact ih _ _
  | reduce extent tail ih =>
    let slice (head : Fin extent) : Tensor tail.inputShape α :=
      fun index => input (Fin.cases head index)
    calc
      (fiberValues (Plan.reduce extent tail) input output).sum =
          ((List.finRange extent).map fun head => (fiberValues tail (slice head) output).sum).sum :=
        sum_flatMap _ _
      _ = ((List.finRange extent).map fun head =>
          ∑ reduced, slice head (mergeIndex tail output reduced)).sum := by
        congr 1
        apply List.map_congr_left
        intro head _
        exact ih _ _
      _ = ∑ head : Fin extent, ∑ reduced, slice head (mergeIndex tail output reduced) :=
        (Fin.sum_univ_def _).symm
      _ = ∑ reduced : Index (shape (Plan.reduce extent tail)),
          input (mergeIndex (Plan.reduce extent tail) output reduced) :=
        (sum_head_tail extent (shape tail)
          (fun reduced => input (mergeIndex (Plan.reduce extent tail) output reduced))).symm

/-- Mapping a fold is sound only when the map preserves each operation and initializer. -/
theorem foldl_map_hom {α β : Type} (f : α → β) (operation : α → α → α)
    (target : β → β → β) (hom : ∀ a b, target (f a) (f b) = f (operation a b))
    (values : List α) (initial : α) :
    (values.map f).foldl target (f initial) = f (values.foldl operation initial) := by
  induction values generalizing initial with
  | nil => rfl
  | cons value values ih =>
    simp only [List.map_cons, List.foldl_cons, hom]
    exact ih _

end TensorRewrite.Theory.ReductionFiber
