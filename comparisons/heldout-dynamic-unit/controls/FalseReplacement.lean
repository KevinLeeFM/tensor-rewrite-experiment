module
import Spec
open TensorRewrite.Pilot Heldout.DynamicUnit
set_option autoImplicit false
namespace Heldout.DynamicUnit.Tests

def s : Shape 1 := fun _ => 5
def t : Shape 2 := fun i => if i.val = 0 then 1 else 5
def p : UnitInsertion s t where
  kept := fun _ => ⟨1, by decide⟩
  increasing := by intro i j h; have hi := i.isLt; have hj := j.isLt; omega
  extent := by decide
  inserted := by decide

def sizes : Shape 2 := fun i => if i.val = 0 then 1 else 2
def starts : Fin 2 → Int := fun i => if i.val = 0 then -12 else 99
theorem conditions : Conditions p sizes where
  fits := by decide
  unitWidth := by decide

def input : Tensor s Nat := fun i => (i 0).val
def output : Index sizes := fun i => ⟨0, by dsimp [sizes]; split <;> decide⟩

/-- Valid nonempty example: the large retained-axis start clamps to three. -/
example : slice starts conditions.fits (reshape p input) output = 3 := by decide
example : reshape (outputInsertion p sizes conditions)
    (slice (sourceStarts p starts) (sourceSizes_fit p sizes conditions) input) output = 3 := by decide
/-- A wrong start mapping selects zero, a different value at the same valid output. -/
def wrongStarts : Fin 1 → Int := fun _ => 0
example : reshape (outputInsertion p sizes conditions)
    (slice wrongStarts (sourceSizes_fit p sizes conditions) input) output = 0 := by decide
example : slice starts conditions.fits (reshape p input) output ≠
    reshape (outputInsertion p sizes conditions)
      (slice wrongStarts (sourceSizes_fit p sizes conditions) input) output := by decide

/-- The unit-width partition excludes an otherwise bounded zero-width unit slice. -/
def zeroUnitSizes : Shape 2 := fun i => if i.val = 0 then 0 else 2
example : ∀ i, zeroUnitSizes i ≤ t i := by decide
example : ¬ Conditions p zeroUnitSizes := by
  intro h
  have hu := h.unitWidth ⟨0, by decide⟩ (by decide)
  exact (by decide : (0 : Nat) ≠ 1) hu

/-- A retained non-unit slice may still have zero width; its output is empty. -/
def emptySizes : Shape 2 := fun i => if i.val = 0 then 1 else 0
theorem emptyConditions : Conditions p emptySizes where
  fits := by decide
  unitWidth := by decide
example : ¬ Nonempty (Index emptySizes) := by
  intro ⟨i⟩
  exact Fin.elim0 (i ⟨1, by decide⟩)
/-- Well-typed false replacement, rejected at the nonempty clamped-start witness. -/
example : slice starts conditions.fits (reshape p input) output =
    reshape (outputInsertion p sizes conditions)
      (slice wrongStarts (sourceSizes_fit p sizes conditions) input) output := by decide
end Heldout.DynamicUnit.Tests
