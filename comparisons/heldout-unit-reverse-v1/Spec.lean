module

public import TensorRewrite.Pilot.Indexing

/-! Logical reversal through an order-preserving insertion of unit axes.
Source translation and layout-insensitive pure HLO interpretation are assumptions.
No C++ correspondence, physical layout or helper-recognition completeness is asserted. -/

@[expose] public section
set_option autoImplicit false
namespace TensorRewrite.Heldout.UnitReverse
open Pilot

/-- Retain input axes in order, preserve their extents, and fill every other axis with one.
Zero input extents and scalar ranks are permitted; no input axis is deleted. -/
structure UnitInsertion {inputRank outputRank : Nat}
    (inputShape : Shape inputRank) (outputShape : Shape outputRank) where
  /-- Position of each retained input axis in the output shape. -/
  keptAxis : Fin inputRank → Fin outputRank
  /-- Input-axis order is retained by this reshape. -/
  increasing : ∀ i j, i < j → keptAxis i < keptAxis j
  /-- Retained axes preserve their sizes, including zero and one. -/
  extent : ∀ i, outputShape (keptAxis i) = inputShape i
  /-- Every newly inserted axis has unit size. -/
  insertedUnit : ∀ j, (∀ i, keptAxis i ≠ j) → outputShape j = 1

/-- Drop inserted coordinates while preserving each retained coordinate. -/
def project {n m : Nat} {s : Shape n} {t : Shape m}
    (p : UnitInsertion s t) (index : Index t) : Index s :=
  fun i => Fin.cast (p.extent i) (index (p.keptAxis i))

/-- The logical unit-insertion reshape, using its coordinate projection. -/
def reshape {α : Type} {n m : Nat} {s : Shape n} {t : Shape m}
    (p : UnitInsertion s t) (input : Tensor s α) : Tensor t α :=
  Tensor.reindex (project p) input

/-- Remap selected retained axes and discard all unit axes, as the source loop does. -/
def remappedAxes {n m : Nat} {s : Shape n} {t : Shape m}
    (p : UnitInsertion s t) (axes : Fin m → Bool) : Fin n → Bool :=
  fun i => if s i = 1 then false else axes (p.keptAxis i)

/-- Original Reverse(Reshape(input)) and replacement Reshape(Reverse(input)) agree
for every value type, arbitrary ranks, legal unit-insertion plan and axis mask. -/
def Goal : Prop :=
  ∀ (α : Type) (n m : Nat) (s : Shape n) (t : Shape m)
    (p : UnitInsertion s t) (axes : Fin m → Bool) (input : Tensor s α),
    Tensor.reverse axes (reshape p input) =
      reshape p (Tensor.reverse (remappedAxes p axes) input)

end TensorRewrite.Heldout.UnitReverse
