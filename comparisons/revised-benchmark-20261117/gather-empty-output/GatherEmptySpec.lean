import Std
namespace RevisedBenchmark.GatherEmpty

inductive Role where | window | collapsed | batched deriving DecidableEq, Repr
structure Axis where
  extent : Nat
  width : Nat
  role : Role
deriving DecidableEq, Repr

def windowWidths (xs : List Axis) :=
  (xs.filter fun a => a.role == .window).map Axis.width

/-- Nonvector indices dimensions in their original order, including batch partners.
The correspondence to a valid raw gather is a translation assumption. -/
def Legal (xs : List Axis) (batch : List Nat) : Prop :=
  ∀ a ∈ xs, a.width ≤ a.extent ∧
    (a.role ≠ .window → a.width ≤ 1) ∧
    (a.role = .batched → a.extent ∈ batch)

/-- Scanning offset_dims interleaves visible slice widths with nonvector indices dimensions. -/
inductive Interleave : List Nat → List Nat → List Nat → Prop
  | nil : Interleave [] [] []
  | win {w b o} (n : Nat) (h : Interleave w b o) : Interleave (n :: w) b (n :: o)
  | idx {w b o} (n : Nat) (h : Interleave w b o) : Interleave w (n :: b) (n :: o)

/-- One byte per static dense U8 output element. Empty operand skips all payload writes. -/
def evaluator (shape : List Nat) : List (BitVec 8) :=
  List.replicate shape.prod (BitVec.ofNat 8 0)

/-- Output-shaped scalar broadcast enumerates destination element addresses. -/
def replacement (shape : List Nat) (value : BitVec 8) :=
  (List.range shape.prod).map (fun _ => value)

def Goal := ∀ (xs : List Axis) (batch out : List Nat), Legal xs batch →
  (∃ a ∈ xs, a.extent = 0) → Interleave (windowWidths xs) batch out →
  (out.prod = 0 ↔ 0 ∈ windowWidths xs ∨ 0 ∈ batch) ∧
  (out.prod ≠ 0 → ∀ a ∈ xs, a.extent = 0 → a.role = .collapsed) ∧
  (∀ z, evaluator out = replacement out z ↔ out.prod = 0 ∨ z = 0) ∧
  evaluator out = replacement out 0
end RevisedBenchmark.GatherEmpty
