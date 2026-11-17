module
public import TensorRewrite.Pilot.Indexing
public import TensorRewrite.Pilot.DynamicIndex
/-! Logical unit-axis insertion and DynamicSlice: candidate proposition only. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.DynamicUnit
open TensorRewrite.Pilot TensorRewrite.Pilot.DynamicIndex

/-- Retain the input axes in order and insert unit axes; deletion is outside this partition. -/
structure UnitInsertion {n m : Nat} (s : Shape n) (t : Shape m) where
  kept : Fin n → Fin m
  increasing : ∀ i j, i < j → kept i < kept j
  extent : ∀ i, t (kept i) = s i
  inserted : ∀ j, (∀ i, kept i ≠ j) → t j = 1

/-- Projection is the logical reshape map for the order-preserving insertion. -/
def project {n m : Nat} {s : Shape n} {t : Shape m}
    (p : UnitInsertion s t) (i : Index t) : Index s :=
  fun j => Fin.cast (p.extent j) (i (p.kept j))

def reshape {n m : Nat} {s : Shape n} {t : Shape m} {α : Type}
    (p : UnitInsertion s t) (input : Tensor s α) : Tensor t α :=
  Tensor.reindex (project p) input

/-- The source leaves input-unit slice widths at one and maps all other widths. -/
def sourceSizes {n m : Nat} {s : Shape n} {t : Shape m}
    (p : UnitInsertion s t) (sizes : Shape m) : Shape n :=
  fun i => if s i = 1 then 1 else sizes (p.kept i)

/-- The source uses zero for input-unit starts and maps the other starts. -/
def sourceStarts {n m : Nat} {s : Shape n} {t : Shape m}
    (p : UnitInsertion s t) (starts : Fin m → Int) : Fin n → Int :=
  fun i => if s i = 1 then 0 else starts (p.kept i)

/-- Explicit partition: every unit output axis is sliced at width one. This is a model
restriction, not a guard established in the source branch. -/
structure Conditions {n m : Nat} {s : Shape n} {t : Shape m}
    (p : UnitInsertion s t) (sizes : Shape m) : Prop where
  fits : ∀ j, sizes j ≤ t j
  unitWidth : ∀ j, t j = 1 → sizes j = 1

/-- The source-derived sizes fit the original input. -/
theorem sourceSizes_fit {n m : Nat} {s : Shape n} {t : Shape m}
    (p : UnitInsertion s t) (sizes : Shape m) (c : Conditions p sizes) :
    ∀ i, sourceSizes p sizes i ≤ s i := by
  intro i
  by_cases h : s i = 1
  · simp [sourceSizes, h]
  · simpa [sourceSizes, h, p.extent i] using c.fits (p.kept i)

/-- Source output sizes retain the same axis insertion. -/
def outputInsertion {n m : Nat} {s : Shape n} {t : Shape m}
    (p : UnitInsertion s t) (sizes : Shape m) (c : Conditions p sizes) :
    UnitInsertion (sourceSizes p sizes) sizes where
  kept := p.kept
  increasing := p.increasing
  extent := by
    intro i
    by_cases h : s i = 1
    · have ht : t (p.kept i) = 1 := (p.extent i).trans h
      simp [sourceSizes, h, c.unitWidth _ ht]
    · simp [sourceSizes, h]
  inserted := by
    intro j absent
    exact c.unitWidth j (p.inserted j absent)

/-- Actual logical DynamicSlice, with decoded mathematical integer starts. -/
def slice {rank : Nat} {s size : Shape rank} {α : Type}
    (starts : Fin rank → Int) (fits : ∀ i, size i ≤ s i) (input : Tensor s α) : Tensor size α :=
  Tensor.reindex (dynamicSliceIndex starts fits) input

/-- Complete arbitrary-rank value equality for this insertion/unit-width partition. -/
def Goal : Prop :=
  ∀ (n m : Nat) (s : Shape n) (t : Shape m) (p : UnitInsertion s t)
    (sizes : Shape m) (starts : Fin m → Int) (c : Conditions p sizes)
    (α : Type) (input : Tensor s α),
    slice starts c.fits (reshape p input) =
      reshape (outputInsertion p sizes c) (slice (sourceStarts p starts) (sourceSizes_fit p sizes c) input)

#print Goal
#print axioms Goal
end Heldout.DynamicUnit
