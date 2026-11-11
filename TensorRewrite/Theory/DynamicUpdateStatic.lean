module

public import TensorRewrite.Theory.DynamicUpdateProof

/-! Derived legal static Slice attributes for the decoded-start DynamicSlice operation. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.DynamicUpdate

open Pilot

/-- Derived unit-stride attributes have exactly the declared update extent. -/
theorem static_axis_count {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (axis : Fin rank) :
    (window.staticAxes axis).elementCount = (inner axis : Int) := by
  simp [Window.staticAxes, SliceShape.Axis.elementCount]
  omega

/-- Every generated start/limit/stride is legal for the original input and output shapes. -/
theorem static_axes_valid {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (axis : Fin rank) :
    SliceShape.IsWellFormed (outer axis) (inner axis) (window.staticAxes axis) := by
  have bound := start_bounds window axis
  have count := static_axis_count window axis
  dsimp [SliceShape.IsWellFormed, Window.staticAxes] at *
  constructor
  · omega
  constructor
  · omega
  constructor
  · omega
  constructor
  · decide
  exact ⟨by omega, count⟩

/-- The derived static Slice map equals the actual bounded DynamicSlice map. -/
theorem static_index {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (index : Index inner) :
    IndexMaps.sliceIndex window.staticAxes (static_axes_valid window) index = window.embed index
:= by
  funext axis
  apply Fin.ext
  have static := IndexMaps.sliceIndex_val window.staticAxes (static_axes_valid window) index axis
  have dynamic := embed_value window index axis
  simp only [Window.staticAxes, Int.one_mul] at static
  omega

/-- DynamicSlice equals the static unit-stride Slice with derived, legal clamped attributes. -/
theorem slice_static {rank : Nat} {outer inner : Shape rank} {α : Type}
    (window : Window outer inner) (input : Tensor outer α) :
    window.slice input =
      (fun i => input (IndexMaps.sliceIndex window.staticAxes (static_axes_valid window) i)) := by
  funext index
  exact congrArg input (static_index window index).symm

/-- The actual derived unit-stride static Slice of a matching update returns its update tensor. -/
theorem static_slice_update {rank : Nat} {outer inner : Shape rank} {α : Type}
    (window : Window outer inner) (base : Tensor outer α) (update : Tensor inner α) :
    (fun i => window.update base update
      (IndexMaps.sliceIndex window.staticAxes (static_axes_valid window) i)) = update := by
  rw [← slice_static]
  exact slice_update window base update

/-- The actual derived inner unit-stride static Slice reads a contained portion of the update. -/
theorem static_slice_update_inside {rank : Nat} {outer middle inner : Shape rank} {α : Type}
    (first : Window outer middle) (second : Window middle inner)
    (base : Tensor outer α) (update : Tensor middle α) :
    (fun i => first.update base update (IndexMaps.sliceIndex
      (first.compose second).staticAxes (static_axes_valid (first.compose second)) i)) =
      second.slice update := by
  rw [← slice_static]
  exact slice_update_inside first second base update

end TensorRewrite.Theory.DynamicUpdate
