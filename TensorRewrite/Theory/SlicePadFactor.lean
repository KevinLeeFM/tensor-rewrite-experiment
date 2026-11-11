module

public import TensorRewrite.Theory.SlicePadLemmas
public import TensorRewrite.Theory.ReductionWindowAlgebra
public import TensorRewrite.Pilot.IndexMapLemmas

/-! A constructed Map -> Slice -> Pad graph equals the bounded affine gather. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.SlicePad

open Pilot

/-- The replacement Slice uses computed ordinary attributes with proved well-formedness. -/
def slicePlan {rank : Nat} (plan : ReductionWindow.Plan rank) : Slice rank where
  inputShape := plan.inputShape
  outputShape := fun axis => (windowAxis plan axis).count
  axes := fun axis => (windowAxis plan axis).attributes
  valid := fun axis => attributes_valid (windowAxis plan axis)

/-- Nonnegative boundary padding reconstructs every original output coordinate. -/
def paddingPlan {rank : Nat} (plan : ReductionWindow.Plan rank) : Padding rank where
  low := fun axis => (windowAxis plan axis).first
  high := fun axis => (windowAxis plan axis).outputExtent - (windowAxis plan axis).last

/-- The constructed Slice and Pad graph has exactly the original output shape. -/
theorem graph_shape {rank : Nat} (plan : ReductionWindow.Plan rank) :
    (paddingPlan plan).outputShape (slicePlan plan).outputShape = plan.outputShape := by
  funext axis
  exact padded_extent (windowAxis plan axis)

/-- Transport observations across the derived shape equality, preserving coordinate values. -/
def outputIndex {rank : Nat} (plan : ReductionWindow.Plan rank)
    (output : Index plan.outputShape) :
    Index ((paddingPlan plan).outputShape (slicePlan plan).outputShape) :=
  fun axis => Fin.cast (congrFun (graph_shape plan) axis).symm (output axis)

/-- The actual replacement graph maps the input, slices it, then pads its boundary. -/
def graph {rank : Nat} {α β : Type} (plan : ReductionWindow.Plan rank) (fill : β) (f : α → β)
    (input : Tensor plan.inputShape α) : Tensor plan.outputShape β := fun output =>
  (paddingPlan plan).tensor fill ((slicePlan plan).tensor (Tensor.map f input))
    (outputIndex plan output)

/-- The two stages of the constructed graph admit exactly the affine gather's valid outputs. -/
theorem padding_admission {rank : Nat} (plan : ReductionWindow.Plan rank)
    (output : Index plan.outputShape) :
    (∀ axis, (ReductionWindow.boundedIndex? ((slicePlan plan).outputShape axis)
      (((outputIndex plan output axis).val : Int) - (paddingPlan plan).low axis)).isSome) ↔
    (∀ axis, (ReductionWindow.boundedIndex? ((plan.window axis).inputExtent)
      (ReductionWindow.affinePosition plan output axis)).isSome) := by
  apply forall_congr'
  intro axis
  exact (pad_interval (windowAxis plan axis) (output axis)).trans
    ((valid_interval (windowAxis plan axis) (output axis)).trans
      (bounded_isSome _ _).symm)

/-- Composing the actual Pad and Slice index maps reconstructs the affine input map. -/
theorem graph_index {rank : Nat} (plan : ReductionWindow.Plan rank)
    (output : Index plan.outputShape) :
    ((paddingPlan plan).input? (slicePlan plan).outputShape (outputIndex plan output)).map
      (IndexMaps.sliceIndex (slicePlan plan).axes (slicePlan plan).valid) =
        ReductionWindow.affineInput? plan output := by
  have admission := padding_admission plan output
  unfold Padding.input? ReductionWindow.affineInput?
  by_cases valid : ∀ axis, (ReductionWindow.boundedIndex? ((plan.window axis).inputExtent)
      (ReductionWindow.affinePosition plan output axis)).isSome
  · have padValid := admission.mpr valid
    rw [dite_eq_left padValid, dite_eq_left valid]
    simp only [Option.map_some]
    congr 1
    funext axis
    apply Fin.ext
    apply Int.ofNat_inj.mp
    have interior := (pad_interval (windowAxis plan axis) (output axis)).mp (padValid axis)
    have selected := IndexMaps.sliceIndex_val (slicePlan plan).axes (slicePlan plan).valid
      (fun i => (ReductionWindow.boundedIndex? ((slicePlan plan).outputShape i)
        (((outputIndex plan output i).val : Int) - (paddingPlan plan).low i)).get (padValid i)) axis
    have padValue := bounded_value ((slicePlan plan).outputShape axis)
      (((outputIndex plan output axis).val : Int) - (paddingPlan plan).low axis) (padValid axis)
    have sourceValue := bounded_value ((plan.window axis).inputExtent)
      (ReductionWindow.affinePosition plan output axis) (valid axis)
    rw [padValue] at selected
    exact selected.trans ((coordinate_after_pad (windowAxis plan axis) (output axis) interior).trans
      sourceValue.symm)
  · have padInvalid := mt admission.mp valid
    rw [dite_eq_right padInvalid, dite_eq_right valid]
    rfl

/-- The separately defined Map/Slice/Pad graph preserves the complete affine gather tensor. -/
theorem graph_gather {rank : Nat} {α β : Type} (plan : ReductionWindow.Plan rank)
    (fill : β) (f : α → β) (input : Tensor plan.inputShape α) :
    graph plan fill f input = ReductionWindow.gatherMap plan fill f input := by
  funext output
  have same := graph_index plan output
  unfold graph Padding.tensor Slice.tensor ReductionWindow.gatherMap
  cases pad : (paddingPlan plan).input? (slicePlan plan).outputShape (outputIndex plan output) with
  | none => simp only [pad, Option.map_none] at same ⊢; rw [← same]
  | some index => simp only [pad, Option.map_some] at same ⊢; rw [← same]; rfl

/-- Unit-window reduction equals the separately constructed Map/Slice/Pad replacement graph. -/
theorem unit_window_graph {rank : Nat} {α : Type} (plan : ReductionWindow.Plan rank)
    (unit : ReductionWindow.IsUnit plan) (undilated : ReductionWindow.IsUndilated plan)
    (operation : α → α → α) (initial padding : α)
    (fixed : operation initial padding = padding) (input : Tensor plan.inputShape α) :
    ReductionWindow.reduce plan operation initial padding input =
      graph plan padding (operation initial) input :=
  (ReductionWindow.unit_gather plan unit undilated operation initial padding fixed input).trans
    (graph_gather plan padding (operation initial) input).symm

/-- Exact neutral addition uses the ordinary Slice/Pad graph without a residual scalar update. -/
theorem unit_window_add_zero {rank : Nat} {α : Type} [AddZeroClass α]
    (plan : ReductionWindow.Plan rank) (unit : ReductionWindow.IsUnit plan)
    (undilated : ReductionWindow.IsUndilated plan) (input : Tensor plan.inputShape α) :
    ReductionWindow.reduce plan (· + ·) 0 0 input = graph plan 0 id input :=
  (ReductionWindow.unit_gather_add_zero plan unit undilated input).trans
    (graph_gather plan 0 id input).symm

/-- Linear-order minimum maps values before the constructed Slice and initializer padding. -/
theorem unit_window_min {rank : Nat} {α : Type} [LinearOrder α]
    (plan : ReductionWindow.Plan rank) (unit : ReductionWindow.IsUnit plan)
    (undilated : ReductionWindow.IsUndilated plan) (initial : α)
    (input : Tensor plan.inputShape α) :
    ReductionWindow.reduce plan min initial initial input =
      graph plan initial (fun x => min x initial) input :=
  (ReductionWindow.unit_gather_min plan unit undilated initial input).trans
    (graph_gather plan initial (fun x => min x initial) input).symm

/-- Linear-order maximum has the same derived shape/index factorization with its scalar map. -/
theorem unit_window_max {rank : Nat} {α : Type} [LinearOrder α]
    (plan : ReductionWindow.Plan rank) (unit : ReductionWindow.IsUnit plan)
    (undilated : ReductionWindow.IsUndilated plan) (initial : α)
    (input : Tensor plan.inputShape α) :
    ReductionWindow.reduce plan max initial initial input =
      graph plan initial (fun x => max x initial) input :=
  (ReductionWindow.unit_gather_max plan unit undilated initial input).trans
    (graph_gather plan initial (fun x => max x initial) input).symm

end TensorRewrite.Theory.SlicePad
