module

public import TensorRewrite.Pilot.ReducerIndex

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.ReducerIndex

namespace ScatterRoles

/-- Ordinary current-plus-update addition makes the single-update word rewrite valid. -/
theorem current_update_preserves {size width : Nat} (lhs base : Fin size → BitVec width)
    (target : Fin size) (update : BitVec width) :
    before .current .update lhs base target update =
      after .current .update lhs base target update := by
  funext index
  by_cases same : index = target
  · simp [before, after, scatter, combine, parameterValue, same, BitVec.add_assoc]
  · simp [before, after, scatter, same]

/-- Swapping the two distinct Add parameters also preserves single-update word values. -/
theorem update_current_preserves {size width : Nat} (lhs base : Fin size → BitVec width)
    (target : Fin size) (update : BitVec width) :
    before .update .current lhs base target update =
      after .update .current lhs base target update := by
  funext index
  by_cases same : index = target
  · simp only [before, after, scatter, ite_eq_left same, combine, parameterValue]
    rw [← BitVec.add_assoc (lhs index) update (base index),
      BitVec.add_comm (lhs index) update, BitVec.add_assoc]
  · simp [before, after, scatter, same]

/-- Distinct parameter roles suffice; the source opcode-only matcher does not require this. -/
theorem distinct_parameters_preserve {size width : Nat} (first second : Parameter)
    (distinct : first ≠ second) (lhs base : Fin size → BitVec width)
    (target : Fin size) (update : BitVec width) :
    before first second lhs base target update = after first second lhs base target update := by
  cases first <;> cases second
  · exact False.elim (distinct rfl)
  · exact current_update_preserves lhs base target update
  · exact update_current_preserves lhs base target update
  · exact False.elim (distinct rfl)

end ScatterRoles

namespace GatherLiterals

/-- Exact signed representation of every generated position makes the Select chain a clamp. -/
theorem selectedIndex_eq_original {width : Nat} (extent : Nat) (index : BitVec width)
    (represented : ∀ position, position < extent →
      (BitVec.ofNat width position).toInt = (position : Int)) :
    selectedIndex extent index = originalIndex extent index := by
  induction extent with
  | zero => simp [selectedIndex, originalIndex]
  | succ n previous =>
    have exactLiteral := represented n (by omega)
    have earlier := previous (fun position bound => represented position (by omega))
    simp only [selectedIndex, List.range_succ, List.foldl_append,
      List.foldl_cons, List.foldl_nil]
    change (if index.toInt ≥ (BitVec.ofNat width n).toInt then n else selectedIndex n index) =
      min n index.toInt.toNat
    rw [exactLiteral, earlier]
    unfold originalIndex
    by_cases lower : (n : Int) ≤ index.toInt
    · simp only [lower, ↓reduceIte]
      omega
    · simp only [lower, ↓reduceIte]
      by_cases empty : n = 0
      · subst n; simp
      · have bound : index.toInt.toNat ≤ n - 1 := by omega
        rw [Nat.min_eq_right bound, Nat.min_eq_right (by omega)]

end GatherLiterals
end TensorRewrite.Pilot.ReducerIndex
