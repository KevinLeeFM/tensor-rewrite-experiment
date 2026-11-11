module

public import TensorRewrite.Pilot.DynamicSliceComposition
public import TensorRewrite.Pilot.IndexMapLemmas

/-! Bounded decoded-index DynamicSlice/UpdateSlice semantics. Raw starts are mathematical Int;
clamping is computed independently on each axis and update membership is derived from coordinates.
-/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.DynamicUpdate

open Pilot

/-- A same-rank update window with actual decoded starts and a checked extent fit. -/
structure Window {rank : Nat} (outer inner : Shape rank) where
  starts : Fin rank → Int
  fits : ∀ axis, inner axis ≤ outer axis

/-- The actual nonnegative clamped start along one axis. -/
def Window.start {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (axis : Fin rank) : Nat :=
  (DynamicIndex.clampStart (outer axis) (inner axis) (window.starts axis)).toNat

/-- Embed an update coordinate into its bounded base coordinate using the actual clamped map. -/
def Window.embed {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) : Index inner → Index outer :=
  DynamicIndex.dynamicSliceIndex window.starts window.fits

/-- Decode a base coordinate only when every axis lies in the actual update interval. -/
def Window.locate {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (index : Index outer) : Option (Index inner) :=
  if inside : ∀ axis, window.start axis ≤ (index axis).val ∧
      (index axis).val < window.start axis + inner axis then
    some (fun axis => ⟨(index axis).val - window.start axis, by
      have bounds := inside axis
      omega⟩)
  else none

/-- Read the actual bounded DynamicSlice, preserving all values and their order. -/
def Window.slice {rank : Nat} {outer inner : Shape rank} {α : Type}
    (window : Window outer inner) (input : Tensor outer α) : Tensor inner α :=
  fun index => input (window.embed index)

/-- Write update values on the derived window and retain base values everywhere else. -/
def Window.update {rank : Nat} {outer inner : Shape rank} {α : Type}
    (window : Window outer inner) (base : Tensor outer α) (update : Tensor inner α) :
    Tensor outer α := fun index =>
  match window.locate index with
  | none => base index
  | some localIndex => update localIndex

/-- Compose independently clamped outer and inner starts, with the transitive extent fit. -/
def Window.compose {rank : Nat} {outer middle inner : Shape rank}
    (first : Window outer middle) (second : Window middle inner) : Window outer inner where
  starts axis := DynamicIndex.combinedStart (outer axis) (middle axis) (inner axis)
    (first.starts axis) (second.starts axis)
  fits axis := Nat.le_trans (second.fits axis) (first.fits axis)

/-- Replace decoded starts on full-extent axes by zero, retaining every other raw start. -/
def Window.zeroFullAxes {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) : Window outer inner where
  starts axis := if inner axis = outer axis then 0 else window.starts axis
  fits := window.fits

/-- Static unit-stride Slice attributes derived from the actual clamped dynamic starts. -/
def Window.staticAxes {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (axis : Fin rank) : SliceShape.Axis where
  start := window.start axis
  limit := (window.start axis : Int) + inner axis
  stride := 1

end TensorRewrite.Theory.DynamicUpdate
