module
public import MixedSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.ConvMixedU32
open ConvPointAxes

private theorem bound {t : Storage} {shape : Coord} (x : Operand t shape) (i : Coord) :
    read (toResult x) i < limit t := by
  unfold ConvPointAxes.read
  split
  next h =>
    exact Nat.lt_of_le_of_lt (Nat.mod_le _ _) (x ⟨i,h⟩).isLt
  next => cases t <;> decide

private theorem small {t : Storage} {shape : Coord} (x : Operand t shape) (i : Coord) :
    read (toResult x) i ≤ 4294967295 := by
  have := bound x i
  cases t <;> simp [limit] at this <;> omega

theorem criterion (a b : Storage) (s : Sizes) (legal : Legal s) (l k o : Order)
    (y : Coord) (fits : Fits (outShape s o) y) (x : Operand a (lhsShape s l))
    (w : Operand b (rhsShape s k)) :
    let p := product s l k o y (toResult x) (toResult w)
    evaluated s l k o y x w = emitted s l k o y x w ↔
      p < 4294967296 ∨ p % 4294967296 = 4294967295 := by
  let p := product s l k o y (toResult x) (toResult w)
  have eqn := ((ConvPointAxes.verified s legal).2 l k o).2.2.2 y fits
  have no64 : p < 18446744073709551616 :=
    Nat.lt_of_le_of_lt (Nat.mul_le_mul (small x _) (small w _)) (by decide)
  change min (doConv _ _ _ _ _ _ _ % _) _ % _ = p % _ ↔ _
  rw [eqn.2.2.2.2, Nat.mod_eq_of_lt no64]
  change min p 4294967295 % 4294967296 = p % 4294967296 ↔ _
  by_cases h : p < 4294967296
  · rw [Nat.min_eq_left (by omega)]
    exact ⟨fun _ => Or.inl h, fun _ => rfl⟩
  · rw [Nat.min_eq_right (by omega)]
    simp [p] at h ⊢
    omega

theorem bytePair : Universal .byte .byte := by
  intro s legal l k o y fits x w
  apply (criterion _ _ s legal l k o y fits x w).2
  left
  have bx := bound x (inverseRead l o y)
  have bw := bound w (newK s k o y)
  simp only [limit] at bx bw
  exact Nat.lt_of_le_of_lt (Nat.mul_le_mul (Nat.le_of_lt_succ bx) (Nat.le_of_lt_succ bw)) (by decide)

private def order : Order where
  slot | .batch => 0 | .feature => 1 | .space => 2
  role p := if p=0 then .batch else if p=1 then .feature else .space
  slot_role := by decide
  role_slot := by intro a; cases a <;> rfl
private def exampleSizes : Sizes := ⟨1,2,1,1⟩
private def zero : Coord := fun _ => 0
private theorem legalExample : Legal exampleSizes := by unfold Legal; decide
private theorem fitExample : Fits (outShape exampleSizes order) zero := by unfold Fits; decide

theorem leftCastFailure : ¬ Universal .byte .word := by
  intro h
  have invalid := h exampleSizes legalExample order order order zero fitExample
    (fun _ => ⟨2,by decide⟩) (fun _ => ⟨4294967295,by decide⟩)
  exact (by decide : ¬ evaluated exampleSizes order order order zero
    (a := .byte) (b := .word) (fun _ => ⟨2,by decide⟩) (fun _ => ⟨4294967295,by decide⟩) = _) invalid

theorem rightCastFailure : ¬ Universal .word .byte := by
  intro h
  have invalid := h exampleSizes legalExample order order order zero fitExample
    (fun _ => ⟨4294967295,by decide⟩) (fun _ => ⟨2,by decide⟩)
  exact (by decide : ¬ evaluated exampleSizes order order order zero
    (a := .word) (b := .byte) (fun _ => ⟨4294967295,by decide⟩) (fun _ => ⟨2,by decide⟩) = _) invalid

theorem singleCastFailures : ¬ Universal .byte .word ∧ ¬ Universal .word .byte :=
  ⟨leftCastFailure,rightCastFailure⟩

theorem verified : Goal := ⟨criterion, bytePair, leftCastFailure, rightCastFailure⟩
#print axioms verified
end RevisedBenchmark.ConvMixedU32
