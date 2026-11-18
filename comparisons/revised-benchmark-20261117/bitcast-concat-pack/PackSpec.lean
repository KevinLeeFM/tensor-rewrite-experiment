module
public import TensorRewrite.Theory.BitPackingProof
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.BitcastConcat
open TensorRewrite.Theory.BitPacking

/-- Logical coordinates in all shared dimensions on one side of the concat axis. -/
abbrev Coords (s : List Nat) := (i : Fin s.length) → Fin s[i]

/-- A tensor along the concat axis, with common outer dimensions and a typed cell. -/
structure Block (pre post : List Nat) (α : Type) where
  extent : Nat
  read : Coords pre → Fin extent → Coords post → α

/-- Change only the cell representation at each logical coordinate. -/
def change {pre post : List Nat} {α β : Type} (f : α → β)
    (b : Block pre post α) : Block pre post β :=
  ⟨b.extent, fun p i s => f (b.read p i s)⟩

/-- Concatenation's output axes, before any trailing word-lane dimension. -/
def shape {pre post : List Nat} {α : Type} (xs : List (Block pre post α)) : List Nat :=
  pre ++ [(xs.map Block.extent).sum] ++ post

/-- An entire concat-axis line in left-to-right operand and local index order. -/
def line {pre post : List Nat} {α : Type} (xs : List (Block pre post α))
    (p : Coords pre) (s : Coords post) : List α :=
  xs.flatMap (fun b => List.ofFn (fun i => b.read p i s))

/-- Split one word into a trailing lane dimension in logical stream order. -/
def split (k w : Nat) (o : Order) (x : BitVec (k * w)) : Words k w :=
  repack o o (Nat.one_mul _) (fun _ : Fin 1 => x)

/-- Pack a complete trailing lane dimension into one wide result cell. -/
def pack (k w : Nat) (o : Order) (x : Words k w) : BitVec (k * w) :=
  repack o o (Nat.one_mul _).symm x (0 : Fin 1)

/-- A same-width bitcast on raw bits (signed and unsigned interpretation may differ). -/
def same (w : Nat) (o : Order) (x : BitVec w) : BitVec w :=
  repack o o (inputCells := 1) (outputCells := 1) rfl (fun _ => x) 0

/-- The emitted shape and every full line after inner conversions, concat and inverse conversion.
A lane bundle represents a final logical axis; its size is retained even on empty frames. -/
def Sandwich {α β : Type} (toInner : α → β) (toOuter : β → α) (lastAxes : List Nat) : Prop :=
  ∀ (pre post : List Nat) (first : Block pre post α) (rest : List (Block pre post α)),
    let xs := first :: rest
    let inner := xs.map (change toInner)
    (shape inner ++ lastAxes = shape xs ++ lastAxes) ∧
      ∀ (p : Coords pre) (s : Coords post), (line inner p s).map toOuter = line xs p s

/-- All three width directions on the shared concat axis, for a positive narrow word
and integral widening factor > 1. Equal-width words are handled independently. -/
def Goal : Prop :=
  (∀ (w : Nat), 0 < w → ∀ o : Order, Sandwich (same w o) (same w o) []) ∧
  ∀ (k w : Nat), 1 < k → 0 < w → ∀ o : Order,
    Sandwich (split k w o) (pack k w o) [] ∧
    Sandwich (pack k w o) (split k w o) [k]

end RevisedBenchmark.BitcastConcat
