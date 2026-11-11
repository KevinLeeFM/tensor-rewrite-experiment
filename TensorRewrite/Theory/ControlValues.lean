module

public import TensorRewrite.Pilot.IndexMaps

/-! Pure Select, heterogeneous scalar Map and exact branch-dispatch semantics. Values are
arbitrary Lean types; no numerical algebra or permission to drop execution observations is assumed.
-/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ControlValues

open Pilot

/-- Select a data value at each coordinate using a predicate of the same shape. -/
def select {rank : Nat} {shape : Shape rank} {α : Type}
    (predicate : Tensor shape Bool) (onTrue onFalse : Tensor shape α) : Tensor shape α :=
  fun index => if predicate index then onTrue index else onFalse index

/-- Broadcast by the decoded dimension array and its exact extent equalities. -/
def broadcast {inputRank outputRank : Nat} {inputShape : Shape inputRank}
    {outputShape : Shape outputRank} {α : Type}
    (axes : IndexMaps.BroadcastAxes inputRank outputRank)
    (extents : ∀ axis, inputShape axis = outputShape (axes.decode axis))
    (input : Tensor inputShape α) : Tensor outputShape α :=
  fun index => input (IndexMaps.broadcastIndex axes extents index)

/-- The actual empty dimension array for broadcasting a rank-zero scalar. -/
def scalarAxes (outputRank : Nat) : IndexMaps.BroadcastAxes 0 outputRank where
  values := ⟨#[], rfl⟩
  valid := fun axis => Fin.elim0 axis

/-- Six Boolean comparisons, independently interpreted by the order false=0, true=1. -/
inductive Direction where
  | lt | le | gt | ge | eq | ne
deriving DecidableEq, Repr

/-- Compare Boolean values by their natural-number encodings. -/
def compare (direction : Direction) (left right : Bool) : Bool :=
  match direction with
  | .lt => decide (left.toNat < right.toNat)
  | .le => decide (left.toNat ≤ right.toNat)
  | .gt => decide (right.toNat < left.toNat)
  | .ge => decide (right.toNat ≤ left.toNat)
  | .eq => decide (left.toNat = right.toNat)
  | .ne => decide (left.toNat ≠ right.toNat)

/-- Apply a pure scalar body independently to every coordinate of heterogeneous inputs. -/
def mapTensor {arity rank : Nat} {shape : Shape rank} {β : Type}
    {inputTypes : Fin arity → Type}
    (body : ((argument : Fin arity) → inputTypes argument) → β)
    (inputs : (argument : Fin arity) → Tensor shape (inputTypes argument)) : Tensor shape β :=
  fun index => body (fun argument => inputs argument index)

/-- An ordinary elementwise operation consumes its selected operand tensors directly. -/
def elementwise {arity rank : Nat} {shape : Shape rank} {β : Type}
    {inputTypes : Fin arity → Type}
    (operation : ((argument : Fin arity) → inputTypes argument) → β)
    (operands : (argument : Fin arity) → Tensor shape (inputTypes argument)) : Tensor shape β :=
  fun index => operation (fun argument => operands argument index)

/-- Convert a Boolean to the exact two-branch index, rather than using it as a Select predicate. -/
def booleanIndex (predicate : Bool) : Fin 2 :=
  ⟨predicate.toNat, by cases predicate <;> decide⟩

/-- Invoke exactly one indexed branch with that branch's own typed argument. -/
def indexedConditional {argumentTypes : Fin 2 → Type} {β : Type} (index : Fin 2)
    (arguments : (branch : Fin 2) → argumentTypes branch)
    (branches : (branch : Fin 2) → argumentTypes branch → β) : β :=
  branches index (arguments index)

/-- Invoke the true or false branch, retaining its function and its argument. -/
def predicateConditional {α β γ : Type} (predicate : Bool)
    (trueArgument : α) (trueBranch : α → γ) (falseArgument : β) (falseBranch : β → γ) : γ :=
  if predicate then trueBranch trueArgument else falseBranch falseArgument

end TensorRewrite.Theory.ControlValues
