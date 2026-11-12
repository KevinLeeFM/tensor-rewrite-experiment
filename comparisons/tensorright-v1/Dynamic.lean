module

public import TensorRewrite.Theory.DynamicUpdateStatic
public import TensorRewrite.Theory.ArithmeticFamilyProof

/-! Paper-era valid DynamicSlice and DynamicUpdateSlice graphs. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Dynamic

open Pilot Theory.DynamicUpdate

/-- The paper's valid in-bounds starts are unchanged by the existing model's clamp. -/
theorem unclamped {rank : Nat} {outer inner : Shape rank} (window : Window outer inner)
    (valid : ∀ axis, 0 ≤ window.starts axis ∧
      window.starts axis + (inner axis : Int) ≤ (outer axis : Int)) (axis : Fin rank) :
    DynamicIndex.clampStart (outer axis) (inner axis) (window.starts axis) =
      window.starts axis := by
  have bounds := valid axis
  unfold DynamicIndex.clampStart
  omega

/-- Under paper validity, the generated static Slice begins at the original start. -/
theorem static_start {rank : Nat} {outer inner : Shape rank} (window : Window outer inner)
    (valid : ∀ axis, 0 ≤ window.starts axis ∧
      window.starts axis + (inner axis : Int) ≤ (outer axis : Int)) (axis : Fin rank) :
    (window.staticAxes axis).start = window.starts axis := by
  simp only [Window.staticAxes, Window.start]
  rw [unclamped window valid axis]
  exact Int.toNat_of_nonneg (valid axis).1

/-- `dyslice/rule01`: DynamicSlice equals the derived actual unit-stride static Slice. -/
theorem static_slice {α : Type} {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (input : Tensor outer α) :
    window.slice input =
      (fun index => input (IndexMaps.sliceIndex window.staticAxes
        (static_axes_valid window) index)) :=
  slice_static window input

/-- `dyslice/rule02`: a full-size valid DynamicSlice is the original tensor. -/
theorem full_slice {α : Type} {rank : Nat} {shape : Shape rank}
    (window : Window shape shape) (input : Tensor shape α) : window.slice input = input :=
  slice_full window input

/-- `dyupslice/rule03`: a full-size valid update is the update tensor. -/
theorem full_update {α : Type} {rank : Nat} {shape : Shape rank}
    (window : Window shape shape) (base update : Tensor shape α) :
    window.update base update = update := update_full window base update

/-- `dyupslice/rule01`: push Add into the actual update, preserving the paper's operand order. -/
theorem add_into_update {α : Type} [CommRing α] {rank : Nat} {outer inner : Shape rank}
    (window : Window outer inner) (base : Tensor outer α) (update : Tensor inner α) :
    Tensor.map₂ (· + ·) base (window.update (Tensor.constant 0) update) =
      window.update base (Tensor.map₂ (· + ·) update (window.slice base)) := by
  rw [add_update_right window base update]
  congr 1
  funext index
  exact add_comm _ _

/-- A derived valid window whose starts are the actual sum of the two source starts. -/
def addedWindow {rank : Nat} {outer middle inner : Shape rank}
    (first : Window outer middle) (second : Window middle inner) : Window outer inner where
  starts axis := first.starts axis + second.starts axis
  fits axis := Nat.le_trans (second.fits axis) (first.fits axis)

/-- Under the paper's two validity conditions, composition uses the unmodified summed starts. -/
theorem compose_eq_added {rank : Nat} {outer middle inner : Shape rank}
    (first : Window outer middle) (second : Window middle inner)
    (firstValid : ∀ axis, 0 ≤ first.starts axis ∧
      first.starts axis + (middle axis : Int) ≤ (outer axis : Int))
    (secondValid : ∀ axis, 0 ≤ second.starts axis ∧
      second.starts axis + (inner axis : Int) ≤ (middle axis : Int)) :
    first.compose second = addedWindow first second := by
  simp only [Window.compose, addedWindow, Window.mk.injEq]
  funext axis
  simp only [DynamicIndex.combinedStart]
  rw [unclamped first firstValid axis, unclamped second secondValid axis]

/-- `dyslice/rule05`: valid nested slices equal a slice at the summed starts. -/
theorem nested_slice {α : Type} {rank : Nat} {outer middle inner : Shape rank}
    (first : Window outer middle) (second : Window middle inner)
    (firstValid : ∀ axis, 0 ≤ first.starts axis ∧
      first.starts axis + (middle axis : Int) ≤ (outer axis : Int))
    (secondValid : ∀ axis, 0 ≤ second.starts axis ∧
      second.starts axis + (inner axis : Int) ≤ (middle axis : Int))
    (input : Tensor outer α) :
    second.slice (first.slice input) = (addedWindow first second).slice input := by
  rw [← compose_eq_added first second firstValid secondValid]
  exact slice_compose first second input

/-- `dyupslice/rule04`: nested updates use the actual summed valid starts. -/
theorem nested_update {α : Type} {rank : Nat} {outer middle inner : Shape rank}
    (first : Window outer middle) (second : Window middle inner)
    (firstValid : ∀ axis, 0 ≤ first.starts axis ∧
      first.starts axis + (middle axis : Int) ≤ (outer axis : Int))
    (secondValid : ∀ axis, 0 ≤ second.starts axis ∧
      second.starts axis + (inner axis : Int) ≤ (middle axis : Int))
    (base : Tensor outer α) (update : Tensor inner α) :
    first.update base (second.update (first.slice base) update) =
      (addedWindow first second).update base update := by
  rw [← compose_eq_added first second firstValid secondValid]
  exact update_nested first second base update

#print axioms unclamped
#print axioms static_start
#print axioms static_slice
#print axioms full_slice
#print axioms full_update
#print axioms add_into_update
#print axioms compose_eq_added
#print axioms nested_slice
#print axioms nested_update

end TensorRewrite.PaperComparison.Dynamic
