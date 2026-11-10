module

public import TensorRewrite.Pilot.ConstantGuard

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.ConstantGuard

/-- A successful first/adjacent storage check characterizes every stored value. -/
theorem matchesAll_all (value : Bool) (storage : List Bool) (h : matchesAll value storage = true) :
    ∀ element ∈ storage, element = value := by
  induction storage with
  | nil => simp
  | cons first rest ih =>
    have first_eq : first = value := by
      exact beq_iff_eq.mp (Bool.and_eq_true_iff.mp h).1
    have rest_matches : matchesAll value rest = true := by
      cases rest with
      | nil => rfl
      | cons second tail =>
        simp only [matchesAll, adjacentEqual, Bool.and_eq_true, beq_iff_eq] at h ⊢
        exact ⟨h.2.1.symm.trans first_eq, h.2.2⟩
    intro element member
    cases member with
    | head => exact first_eq
    | tail _ tail_member => exact ih rest_matches element tail_member

/-- Successful storage recognition supplies the tensor constant premise. -/
theorem DenseLiteral.matchesAll_sound {rank : Nat} {shape : Shape rank}
    (literal : DenseLiteral shape) (value : Bool) (h : matchesAll value literal.storage = true) :
    literal.eval = Tensor.constant value := by
  funext index
  exact matchesAll_all value literal.storage h _ (List.getElem_mem (literal.address index).isLt)

/-- Recognition remains sound through any finite chain of legal index wrappers. -/
theorem View.isAll_sound {rank : Nat} {shape : Shape rank} (view : View rank shape)
    (value : Bool) (h : view.isAll value = true) : view.eval = Tensor.constant value := by
  induction view with
  | literal lit => exact lit.matchesAll_sound value h
  | unrecognized _ => cases h
  | reindex _ operand indexMap ih =>
    funext index
    exact congrArg (fun tensor => tensor (indexMap index)) (ih h)

end TensorRewrite.Pilot.ConstantGuard
