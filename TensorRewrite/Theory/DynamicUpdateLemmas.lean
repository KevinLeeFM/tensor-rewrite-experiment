module

public import TensorRewrite.Theory.DynamicUpdate

/-! Derived bounded-window embedding, membership and nested-coordinate laws. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.DynamicUpdate

open Pilot

/-- The computed natural start fits the actual output interval on every axis. -/
theorem start_bounds {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (axis : Fin rank) :
    window.start axis + inner axis ≤ outer axis := by
  have bound := DynamicIndex.clampStart_bounds _ _ (window.fits axis) (window.starts axis)
  unfold Window.start
  omega

/-- Embedding adds the computed natural start to the update coordinate. -/
theorem embed_value {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (index : Index inner) (axis : Fin rank) :
    (window.embed index axis).val = window.start axis + (index axis).val := by
  have value := DynamicIndex.dynamicSliceIndex_val window.starts window.fits index axis
  have bound := DynamicIndex.clampStart_bounds _ _ (window.fits axis) (window.starts axis)
  change ((window.embed index axis).val : Int) = _ at value
  unfold Window.start
  omega

/-- Every embedded update coordinate is recognized and decoded to the original coordinate. -/
theorem locate_embed {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (index : Index inner) :
    window.locate (window.embed index) = some index := by
  have inside : ∀ axis, window.start axis ≤ (window.embed index axis).val ∧
      (window.embed index axis).val < window.start axis + inner axis := by
    intro axis
    rw [embed_value]
    have bound := (index axis).isLt
    omega
  unfold Window.locate
  rw [dite_eq_left inside]
  congr 1
  funext axis
  apply Fin.ext
  simp [embed_value]

/-- A recognized base coordinate is exactly the embedding of its decoded update coordinate. -/
theorem embed_locate {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (index : Index outer) (localIndex : Index inner)
    (located : window.locate index = some localIndex) : window.embed localIndex = index := by
  unfold Window.locate at located
  split at located
  · rename_i inside
    have equal := Option.some.inj located
    rw [← equal]
    funext axis
    apply Fin.ext
    rw [embed_value]
    have bound := (inside axis).1
    simp only [Nat.add_sub_of_le bound]
  · contradiction

/-- Window membership is characterized by the actual bounded embedding, in both directions. -/
theorem locate_eq_some_iff {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (index : Index outer) (localIndex : Index inner) :
    window.locate index = some localIndex ↔ window.embed localIndex = index := by
  constructor
  · exact embed_locate window index localIndex
  · intro equal
    rw [← equal]
    exact locate_embed window localIndex

/-- The composed window's bounded embedding equals the two independently clamped embeddings. -/
theorem embed_compose {rank : Nat} {outer middle inner : Shape rank}
    (first : Window outer middle) (second : Window middle inner) (index : Index inner) :
    (first.compose second).embed index = first.embed (second.embed index) :=
  (DynamicIndex.dynamicSliceIndex_compose first.starts second.starts
    first.fits second.fits index).symm

/-- Nested membership is computed by the two partial coordinate decoders in sequence. -/
theorem locate_compose {rank : Nat} {outer middle inner : Shape rank}
    (first : Window outer middle) (second : Window middle inner) (index : Index outer) :
    (first.compose second).locate index = (first.locate index).bind second.locate := by
  apply Option.ext
  intro localIndex
  rw [Option.bind_eq_some_iff, locate_eq_some_iff]
  simp only [locate_eq_some_iff]
  constructor
  · intro equal
    exact ⟨second.embed localIndex, by simpa only [embed_compose] using equal, rfl⟩
  · rintro ⟨middleIndex, outerEqual, innerEqual⟩
    rw [embed_compose, innerEqual]
    exact outerEqual

/-- Full-size windows start at zero independently of decoded input start values. -/
theorem full_start {rank : Nat} {shape : Shape rank}
    (window : Window shape shape) (axis : Fin rank) : window.start axis = 0 := by
  simp [Window.start, DynamicIndex.clampStart_full_extent]

/-- Full-size bounded embeddings are identity maps. -/
theorem full_embed {rank : Nat} {shape : Shape rank}
    (window : Window shape shape) (index : Index shape) : window.embed index = index := by
  funext axis
  apply Fin.ext
  rw [embed_value, full_start, Nat.zero_add]

/-- Every base coordinate is recognized by a full-size window. -/
theorem full_locate {rank : Nat} {shape : Shape rank}
    (window : Window shape shape) (index : Index shape) : window.locate index = some index :=
  (locate_eq_some_iff window index index).mpr (full_embed window index)

/-- Replacing full-axis decoded starts by zero leaves every computed start unchanged. -/
theorem zero_full_start {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (axis : Fin rank) :
    window.zeroFullAxes.start axis = window.start axis := by
  dsimp [Window.start, Window.zeroFullAxes]
  by_cases full : inner axis = outer axis
  · rw [ite_eq_left full, full]
    simp [DynamicIndex.clampStart_full_extent]
  · rw [ite_eq_right full]

/-- Zeroing full-axis starts preserves the complete bounded embedding. -/
theorem zero_full_embed {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (index : Index inner) :
    window.zeroFullAxes.embed index = window.embed index := by
  funext axis
  apply Fin.ext
  rw [embed_value, embed_value, zero_full_start]

/-- Zeroing full-axis starts preserves every membership decision and decoded update coordinate. -/
theorem zero_full_locate {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (index : Index outer) :
    window.zeroFullAxes.locate index = window.locate index := by
  apply Option.ext
  intro localIndex
  rw [locate_eq_some_iff, locate_eq_some_iff, zero_full_embed]

end TensorRewrite.Theory.DynamicUpdate
