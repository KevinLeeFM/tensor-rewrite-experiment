module

public import TensorRewrite.Theory.UnitAxis
public import Mathlib.Data.Fin.Basic

/-! Cardinality, order and actual row-major Reshape maps for one singleton deletion. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.UnitAxis

open Pilot

/-- The selected original dimension is actually a singleton. -/
theorem axis_unit {rank : Nat} (plan : Plan rank) : plan.inputShape plan.axis = 1 := by
  induction plan with
  | first _ => rfl
  | keep _ _ ih => exact ih

/-- Restoring extent one reconstructs the complete original shape. -/
theorem target_one {rank : Nat} (plan : Plan rank) : plan.targetShape 1 = plan.inputShape := by
  induction plan with
  | first _ => rfl
  | keep _ _ ih =>
    funext axis
    exact Fin.cases rfl (fun axis => congrFun ih axis) axis

/-- Deleting the singleton preserves the actual element count, including empty other axes. -/
theorem count {rank : Nat} (plan : Plan rank) :
    LinearIndex.elementCount plan.inputShape = LinearIndex.elementCount plan.outputShape := by
  induction plan with
  | first tail =>
    change 1 * LinearIndex.elementCount tail = LinearIndex.elementCount tail
    exact Nat.one_mul _
  | keep extent tail ih =>
    change extent * LinearIndex.elementCount tail.inputShape =
      extent * LinearIndex.elementCount tail.outputShape
    rw [ih]

/-- Inserting the actual singleton coordinate preserves row-major linear position. -/
theorem linearize_insert {rank : Nat} (plan : Plan rank) (index : Index plan.outputShape) :
    (LinearIndex.linearize plan.inputShape (plan.insertIndex index)).val =
      (LinearIndex.linearize plan.outputShape index).val := by
  induction plan with
  | first tail =>
    change 0 * LinearIndex.elementCount tail + (LinearIndex.linearize tail index).val =
      (LinearIndex.linearize tail index).val
    omega
  | keep extent tail ih =>
    change (index 0).val * LinearIndex.elementCount tail.inputShape +
      (LinearIndex.linearize tail.inputShape
        (tail.insertIndex (fun axis => index axis.succ))).val =
      (index 0).val * LinearIndex.elementCount tail.outputShape +
        (LinearIndex.linearize tail.outputShape (fun axis => index axis.succ)).val
    exact congrArg₂ (fun count position => (index 0).val * count + position)
      (count tail) (ih (fun axis => index axis.succ))

/-- Ordinary logical Reshape has the derived singleton-insertion coordinate map. -/
theorem reshape_index {rank : Nat} (plan : Plan rank) (index : Index plan.outputShape) :
    Reshape.reshapeIndex plan.inputShape plan.outputShape (count plan) index =
      plan.insertIndex index := by
  unfold Reshape.reshapeIndex
  rw [← LinearIndex.delinearize_linearize plan.inputShape (plan.insertIndex index)]
  congr 1
  apply Fin.ext
  exact (linearize_insert plan index).symm

/-- Constructed signed Broadcast attributes decode to the actual retained-axis map. -/
theorem axes_decode {rank : Nat} (plan : Plan rank) (axis : Fin rank) :
    plan.broadcastAxes.decode axis = plan.axesMap axis := by
  apply Fin.ext
  simp [Plan.broadcastAxes, IndexMaps.BroadcastAxes.decode, Fin.getElem_fin]

/-- Retained dimensions match the requested Broadcast output at their generated axis positions. -/
theorem axes_extent {rank : Nat} (plan : Plan rank) (copies : Nat) (axis : Fin rank) :
    plan.outputShape axis = plan.targetShape copies (plan.axesMap axis) := by
  revert axis
  induction plan with
  | first _ => intro axis; rfl
  | keep _ _ ih =>
    intro axis
    exact Fin.cases rfl (fun axis => ih axis) axis

/-- Generated axis positions are strictly increasing, so legal attributes contain no duplicates. -/
theorem axes_increasing {rank : Nat} (plan : Plan rank) (first second : Fin rank)
    (less : first < second) : plan.axesMap first < plan.axesMap second := by
  revert first second less
  induction plan with
  | first _ =>
    intro first second less
    change first.val + 1 < second.val + 1
    exact Nat.add_lt_add_right less 1
  | keep _ tail ih =>
    intro first
    refine Fin.cases ?_ (fun first => ?_) first
    · intro second
      refine Fin.cases (fun less => ?_) (fun second _ => ?_) second
      · exact False.elim (Nat.lt_irrefl _ less)
      · change 0 < (tail.axesMap second).val + 1
        omega
    · intro second
      refine Fin.cases (fun less => ?_) (fun second less => ?_) second
      · have impossible : first.val + 1 < 0 := less
        omega
      · have inner : first < second := by
          change first.val < second.val
          have bounded : first.val + 1 < second.val + 1 := less
          omega
        change (tail.axesMap first).val + 1 < (tail.axesMap second).val + 1
        exact Nat.add_lt_add_right (ih first second inner) 1

/-- Projected coordinates read exactly the computed retained original-axis positions. -/
theorem projectIndex_value {rank : Nat} (plan : Plan rank) {copies : Nat}
    (index : Index (plan.targetShape copies)) (axis : Fin rank) :
    (plan.projectIndex index axis).val = (index (plan.axesMap axis)).val := by
  revert index axis
  induction plan with
  | first _ => intro index axis; rfl
  | keep _ _ ih =>
    intro index axis
    exact Fin.cases rfl (fun axis => ih (fun axis => index axis.succ) axis) axis

/-- The existing bounded Broadcast map is exactly the retained-coordinate projection. -/
theorem broadcast_index {rank : Nat} (plan : Plan rank) {copies : Nat}
    (index : Index (plan.targetShape copies)) :
    IndexMaps.broadcastIndex plan.broadcastAxes (fun axis => by
      rw [axes_decode]
      exact axes_extent plan copies axis) index = plan.projectIndex index := by
  funext axis
  apply Fin.ext
  change (index (plan.broadcastAxes.decode axis)).val = (plan.projectIndex index axis).val
  exact (congrArg (fun position => (index position).val) (axes_decode plan axis)).trans
    (projectIndex_value plan index axis).symm

/-- Reshape then Broadcast inserts zero only at the selected axis and retains all other values. -/
theorem sourceIndex_value {rank : Nat} (plan : Plan rank) {copies : Nat}
    (index : Index (plan.targetShape copies)) (axis : Fin (rank + 1)) :
    (plan.insertIndex (plan.projectIndex index) axis).val =
      if axis = plan.axis then 0 else (index axis).val := by
  revert index axis
  induction plan with
  | first _ =>
    intro index axis
    refine Fin.cases ?_ (fun axis => ?_) axis
    · rfl
    · change (index axis.succ).val =
        if axis.succ = (0 : Fin _) then 0 else (index axis.succ).val
      rw [ite_eq_right (Fin.succ_ne_zero axis)]
  | keep _ tail ih =>
    intro index axis
    refine Fin.cases ?_ (fun axis => ?_) axis
    · change (index 0).val = if (0 : Fin _) = tail.axis.succ then 0 else (index 0).val
      rw [ite_eq_right (Ne.symm (Fin.succ_ne_zero tail.axis))]
    · change (tail.insertIndex (tail.projectIndex (fun axis => index axis.succ)) axis).val =
        if axis.succ = tail.axis.succ then 0 else (index axis.succ).val
      simpa only [Fin.succ_inj] using ih (fun axis => index axis.succ) axis

/-- Any legal supplied axis is the one selected by the computed deletion plan. -/
theorem axis_ofAxis {rank : Nat} (shape : Shape (rank + 1)) (axis : Fin (rank + 1)) :
    (ofAxis shape axis).axis = axis := by
  induction rank with
  | zero =>
    apply Fin.ext
    have bound := axis.isLt
    change 0 = axis.val
    omega
  | succ rank ih =>
    revert shape
    refine Fin.cases ?_ (fun axis => ?_) axis
    · intro shape
      rfl
    · intro shape
      change (ofAxis (fun axis => shape axis.succ) axis).axis.succ = axis.succ
      rw [ih]

/-- The computed plan changes exactly the chosen dimension at every requested output extent. -/
theorem target_ofAxis {rank : Nat} (shape : Shape (rank + 1)) (axis : Fin (rank + 1))
    (copies : Nat) : (ofAxis shape axis).targetShape copies =
      (fun dimension => if dimension = axis then copies else shape dimension) := by
  induction rank with
  | zero =>
    have axisZero : axis = 0 := by apply Fin.ext; have := axis.isLt; omega
    subst axis
    funext dimension
    have dimensionZero : dimension = 0 := by apply Fin.ext; have := dimension.isLt; omega
    subst dimension
    rfl
  | succ rank ih =>
    revert shape
    refine Fin.cases ?_ (fun axis => ?_) axis
    · intro shape
      funext dimension
      refine Fin.cases ?_ (fun dimension => ?_) dimension
      · rfl
      · change shape dimension.succ =
          if dimension.succ = (0 : Fin _) then copies else shape dimension.succ
        rw [ite_eq_right (Fin.succ_ne_zero dimension)]
    · intro shape
      funext dimension
      refine Fin.cases ?_ (fun dimension => ?_) dimension
      · change shape 0 = if (0 : Fin _) = axis.succ then copies else shape 0
        rw [ite_eq_right (Ne.symm (Fin.succ_ne_zero axis))]
      · change (ofAxis (fun axis => shape axis.succ) axis).targetShape copies dimension =
          if dimension.succ = axis.succ then copies else shape dimension.succ
        simpa only [Fin.succ_inj] using
          congrFun (ih (fun axis => shape axis.succ) axis) dimension

/-- The input of the computed plan is the supplied shape with its chosen extent set to one. -/
theorem input_ofAxis {rank : Nat} (shape : Shape (rank + 1)) (axis : Fin (rank + 1)) :
    (ofAxis shape axis).inputShape =
      (fun dimension => if dimension = axis then 1 else shape dimension) :=
  (target_one (ofAxis shape axis)).symm.trans (target_ofAxis shape axis 1)

end TensorRewrite.Theory.UnitAxis
