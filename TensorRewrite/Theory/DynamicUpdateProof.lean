module

public import TensorRewrite.Theory.DynamicUpdateLemmas
public import Mathlib.Algebra.Group.Defs

/-! Actual bounded Slice/UpdateSlice graphs: nesting, empty/full windows and pointwise rewrites. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.DynamicUpdate

open Pilot

/-- The slice operation is exactly the earlier decoded-start bounded DynamicSlice. -/
theorem slice_eq_existing {rank : Nat} {outer inner : Shape rank} {α : Type}
    (window : Window outer inner) (input : Tensor outer α) :
    window.slice input = DynamicIndex.sliceTensor input window.starts window.fits := rfl

/-- Nested slices use the actual derived combined clamped starts. -/
theorem slice_compose {rank : Nat} {outer middle inner : Shape rank} {α : Type}
    (first : Window outer middle) (second : Window middle inner) (input : Tensor outer α) :
    second.slice (first.slice input) = (first.compose second).slice input := by
  funext index
  exact congrArg input (embed_compose first second index).symm

/-- A full-size DynamicSlice preserves every tensor value for every decoded start. -/
theorem slice_full {rank : Nat} {shape : Shape rank} {α : Type}
    (window : Window shape shape) (input : Tensor shape α) : window.slice input = input := by
  funext index
  exact congrArg input (full_embed window index)

/-- A rank-zero DynamicSlice preserves the unique scalar value regardless of decoded starts. -/
theorem slice_scalar {outer inner : Shape 0} {α : Type}
    (window : Window outer inner) (input : Tensor outer α) :
    window.slice input = Tensor.constant (input (fun axis => Fin.elim0 axis)) := by
  funext index
  apply congrArg input
  funext axis
  exact Fin.elim0 axis

/-- Zeroing full-axis starts leaves the actual DynamicSlice graph unchanged. -/
theorem slice_zero_full_axes {rank : Nat} {outer inner : Shape rank} {α : Type}
    (window : Window outer inner) (input : Tensor outer α) :
    window.zeroFullAxes.slice input = window.slice input := by
  funext index
  exact congrArg input (zero_full_embed window index)

/-- A full-size update replaces every value, independently of decoded starts and base values. -/
theorem update_full {rank : Nat} {shape : Shape rank} {α : Type}
    (window : Window shape shape) (base update : Tensor shape α) :
    window.update base update = update := by
  funext index
  simp [Window.update, full_locate]

/-- An update with an empty axis leaves every base value unchanged. -/
theorem update_empty {rank : Nat} {outer inner : Shape rank} {α : Type}
    (window : Window outer inner) (axis : Fin rank) (empty : inner axis = 0)
    (base : Tensor outer α) (update : Tensor inner α) : window.update base update = base := by
  funext index
  unfold Window.update
  split
  · rfl
  · rename_i localIndex located
    have bound := (localIndex axis).isLt
    omega

/-- Reading the exact update window returns its actual update tensor. -/
theorem slice_update {rank : Nat} {outer inner : Shape rank} {α : Type}
    (window : Window outer inner) (base : Tensor outer α) (update : Tensor inner α) :
    window.slice (window.update base update) = update := by
  funext index
  simp [Window.slice, Window.update, locate_embed]

/-- Reinstalling the actual slice is an identity on the entire base tensor. -/
theorem update_slice_self {rank : Nat} {outer inner : Shape rank} {α : Type}
    (window : Window outer inner) (base : Tensor outer α) :
    window.update base (window.slice base) = base := by
  funext index
  cases located : window.locate index with
  | none => simp [Window.update, located]
  | some localIndex =>
    simp only [Window.update, located, Window.slice]
    exact congrArg base (embed_locate window index localIndex located)

/-- A slice contained in the update window reads the corresponding slice of the update. -/
theorem slice_update_inside {rank : Nat} {outer middle inner : Shape rank} {α : Type}
    (first : Window outer middle) (second : Window middle inner)
    (base : Tensor outer α) (update : Tensor middle α) :
    (first.compose second).slice (first.update base update) = second.slice update := by
  funext index
  simp [Window.slice, Window.update, embed_compose, locate_embed]

/-- An inner update of the original outer slice collapses to one update at derived combined
starts. -/
theorem update_nested {rank : Nat} {outer middle inner : Shape rank} {α : Type}
    (first : Window outer middle) (second : Window middle inner)
    (base : Tensor outer α) (update : Tensor inner α) :
    first.update base (second.update (first.slice base) update) =
      (first.compose second).update base update := by
  funext index
  unfold Window.update
  rw [locate_compose]
  cases located : first.locate index with
  | none => rfl
  | some middleIndex =>
    dsimp only [Option.bind]
    cases second.locate middleIndex with
    | none => exact congrArg base (embed_locate first index middleIndex located)
    | some localIndex => rfl

/-- A pure pointwise map commutes with a concrete bounded update, for arbitrary data types. -/
theorem map_update {rank : Nat} {outer inner : Shape rank} {α β : Type}
    (window : Window outer inner) (f : α → β) (base : Tensor outer α)
    (update : Tensor inner α) :
    Tensor.map f (window.update base update) =
      window.update (Tensor.map f base) (Tensor.map f update) := by
  funext index
  cases located : window.locate index <;> simp [Tensor.map, Window.update, located]

/-- Zeroing full-axis starts leaves every update and retained base coordinate unchanged. -/
theorem update_zero_full_axes {rank : Nat} {outer inner : Shape rank} {α : Type}
    (window : Window outer inner) (base : Tensor outer α) (update : Tensor inner α) :
    window.zeroFullAxes.update base update = window.update base update := by
  funext index
  simp [Window.update, zero_full_locate]

/-- Tensor-predicate Select with an update on its false side restricts Select to the update
window. -/
theorem select_update_false {rank : Nat} {outer inner : Shape rank} {α : Type}
    (window : Window outer inner) (predicate : Tensor outer Bool)
    (base : Tensor outer α) (update : Tensor inner α) :
    (fun i => if predicate i then base i else window.update base update i) =
      window.update base (fun j => if window.slice predicate j then window.slice base j
        else update j) := by
  funext index
  cases located : window.locate index with
  | none => simp [Window.update, located]
  | some localIndex =>
    have equal := embed_locate window index localIndex located
    simp [Window.update, located, Window.slice, equal]

/-- Tensor-predicate Select with an update on its true side restricts Select to the update window.
-/
theorem select_update_true {rank : Nat} {outer inner : Shape rank} {α : Type}
    (window : Window outer inner) (predicate : Tensor outer Bool)
    (base : Tensor outer α) (update : Tensor inner α) :
    (fun i => if predicate i then window.update base update i else base i) =
      window.update base (fun j => if window.slice predicate j then update j
        else window.slice base j) := by
  funext index
  cases located : window.locate index with
  | none => simp [Window.update, located]
  | some localIndex =>
    have equal := embed_locate window index localIndex located
    simp [Window.update, located, Window.slice, equal]

/-- A scalar predicate needs no sliced predicate tensor in the false-update graph. -/
theorem select_scalar_false {rank : Nat} {outer inner : Shape rank} {α : Type}
    (window : Window outer inner) (predicate : Bool) (base : Tensor outer α)
    (update : Tensor inner α) :
    (fun i => if predicate then base i else window.update base update i) =
      window.update base (fun j => if predicate then window.slice base j else update j) :=
  select_update_false window (Tensor.constant predicate) base update

/-- A scalar predicate needs no sliced predicate tensor in the true-update graph. -/
theorem select_scalar_true {rank : Nat} {outer inner : Shape rank} {α : Type}
    (window : Window outer inner) (predicate : Bool) (base : Tensor outer α)
    (update : Tensor inner α) :
    (fun i => if predicate then window.update base update i else base i) =
      window.update base (fun j => if predicate then update j else window.slice base j) :=
  select_update_true window (Tensor.constant predicate) base update

/-- Add with a zero-based update on the right only updates the affected base slice. -/
theorem add_update_right {rank : Nat} {outer inner : Shape rank} {α : Type} [AddZeroClass α]
    (window : Window outer inner) (base : Tensor outer α) (update : Tensor inner α) :
    Tensor.map₂ (· + ·) base (window.update (Tensor.constant 0) update) =
      window.update base (Tensor.map₂ (· + ·) (window.slice base) update) := by
  funext index
  cases located : window.locate index with
  | none => simp [Tensor.map₂, Window.update, located, Tensor.constant]
  | some localIndex =>
    have equal := embed_locate window index localIndex located
    simp [Tensor.map₂, Window.update, located, Window.slice, equal]

/-- Add with a zero-based update on the left preserves the actual operand order inside the window.
-/
theorem add_update_left {rank : Nat} {outer inner : Shape rank} {α : Type} [AddZeroClass α]
    (window : Window outer inner) (base : Tensor outer α) (update : Tensor inner α) :
    Tensor.map₂ (· + ·) (window.update (Tensor.constant 0) update) base =
      window.update base (Tensor.map₂ (· + ·) update (window.slice base)) := by
  funext index
  cases located : window.locate index with
  | none => simp [Tensor.map₂, Window.update, located, Tensor.constant]
  | some localIndex =>
    have equal := embed_locate window index localIndex located
    simp [Tensor.map₂, Window.update, located, Window.slice, equal]

end TensorRewrite.Theory.DynamicUpdate
