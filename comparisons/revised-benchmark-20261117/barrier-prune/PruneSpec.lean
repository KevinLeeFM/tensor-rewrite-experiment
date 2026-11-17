module
public import Std
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.BarrierPrune
universe u

/-- Mark every user-selected position, token, and, for a tuple operand, the
    component whose producer has another use, is the root, or has effects. -/
def keep (tupleOperand : Bool) (users : List Nat) (token protectedProducer : Nat → Bool)
    (i : Nat) : Bool :=
  users.contains i || token i || (tupleOperand && protectedProducer i)

/-- The new operand contains the retained values in their original order. -/
def compact {α : Type u} (mask : Nat → Bool) (xs : List α) : List α :=
  (xs.zipIdx.filter (fun entry => mask entry.2)).map Prod.fst

/-- The new position is the number of earlier retained entries. -/
def newPosition (mask : Nat → Bool) (i : Nat) : Nat :=
  ((List.range i).filter mask).length

/-- Every legal GTE user of the barrier observes its original typed value
    after compaction and renumbering. The two source operand kinds differ in
    how protected producers affect the derived keep mask. -/
def Goal : Prop :=
  ∀ {α : Type u} (xs : List α) (tupleOperand : Bool) (users : List Nat)
    (token protectedProducer : Nat → Bool) (i : Fin xs.length), i.val ∈ users →
    let mask := keep tupleOperand users token protectedProducer
    (compact mask xs)[newPosition mask i.val]? = some xs[i]
end RevisedBenchmark.BarrierPrune
