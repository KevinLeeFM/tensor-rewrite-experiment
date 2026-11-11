module

public import TensorRewrite.Pilot.Tensor

/-! Ordered, arbitrary-axis, arbitrary-arity tensor concatenation. A shape frame keeps every
non-concatenated extent fixed; actual bounded coordinates choose the contributing operand.
-/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Concatenation

open Pilot

/-- Fixed non-concatenated dimensions and a legal concatenation axis. -/
structure Frame (rank : Nat) where
  extents : Shape rank
  axis : Fin rank

/-- Change only the concatenated extent; zero extents on any other axis are retained. -/
def Frame.shape {rank : Nat} (frame : Frame rank) (extent : Nat) : Shape rank :=
  fun axis => if axis = frame.axis then extent else frame.extents axis

/-- Read the bounded coordinate on the actual concatenation axis. -/
def Frame.position {rank extent : Nat} (frame : Frame rank)
    (index : Index (frame.shape extent)) : Fin extent :=
  Fin.cast (by simp [Frame.shape]) (index frame.axis)

/-- Replace the concatenation coordinate while preserving every other bounded coordinate. -/
def Frame.withPosition {rank inputExtent outputExtent : Nat} (frame : Frame rank)
    (index : Index (frame.shape inputExtent)) (position : Fin outputExtent) :
    Index (frame.shape outputExtent) := fun axis =>
  if same : axis = frame.axis then
    Fin.cast (by simp [Frame.shape, same]) position
  else
    Fin.cast (by simp [Frame.shape, same]) (index axis)

/-- Reset the selected coordinate to zero in an extent-one frame. -/
def Frame.rest {rank extent : Nat} (frame : Frame rank)
    (index : Index (frame.shape extent)) : Index (frame.shape 1) :=
  frame.withPosition index 0

/-- Transport a tensor across an actual equality of selected extents, keeping all coordinates. -/
def Frame.castTensor {rank first second : Nat} {α : Type} (frame : Frame rank)
    (same : first = second) (input : Tensor (frame.shape first) α) :
    Tensor (frame.shape second) α :=
  fun index => input (frame.withPosition index ⟨(frame.position index).val, by
    rw [same]
    exact (frame.position index).isLt⟩)

/-- Read a legal unit-stride interval on the concatenation axis, retaining all other axes. -/
def Frame.slice {rank extent : Nat} {α : Type} (frame : Frame rank)
    (input : Tensor (frame.shape extent) α) (start length : Nat) (fits : start + length ≤ extent) :
    Tensor (frame.shape length) α := fun index =>
  input (frame.withPosition index ⟨start + (frame.position index).val, by
    have bound := (frame.position index).isLt
    omega⟩)

/-- One typed operand; its extent is part of its data tensor's type. -/
structure Block {rank : Nat} (frame : Frame rank) (α : Type) where
  extent : Nat
  values : Tensor (frame.shape extent) α

/-- Sum operand extents in their original order. -/
def total {rank : Nat} {frame : Frame rank} {α : Type} : List (Block frame α) → Nat
  | [] => 0
  | block :: blocks => block.extent + total blocks

/-- Select the contributing operand by successive actual segment bounds, with no default value. -/
def readAt {rank : Nat} {frame : Frame rank} {α : Type} :
    (blocks : List (Block frame α)) → Index (frame.shape 1) →
      (position : Nat) → position < total blocks → α
  | [], _, position, bound => False.elim (Nat.not_lt_zero position bound)
  | block :: blocks, rest, position, bound =>
    if before : position < block.extent then
      block.values (frame.withPosition rest ⟨position, before⟩)
    else
      readAt blocks rest (position - block.extent) (by
        change position < block.extent + total blocks at bound
        omega)

/-- Concatenate by reading the actual output coordinate through the ordered operand segments. -/
def concatenate {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) : Tensor (frame.shape (total blocks)) α := fun index =>
  readAt blocks (frame.rest index) (frame.position index).val (frame.position index).isLt

/-- Regard an already concatenated group as a single operand for nested concatenation. -/
def pack {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) : Block frame α :=
  ⟨total blocks, concatenate blocks⟩

/-- Remove zero concatenation extents, without confusing them with other empty dimensions. -/
def filterZero {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) : List (Block frame α) :=
  blocks.filter (fun block => block.extent != 0)

/-- Test whether every actual tensor extent is positive. -/
def Block.hasElements {rank : Nat} {frame : Frame rank} {α : Type}
    (block : Block frame α) : Bool :=
  (List.finRange rank).all (fun axis => decide (0 < frame.shape block.extent axis))

/-- Filter by actual tensor emptiness, including zeros on non-concatenated axes. -/
def filterEmpty {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) : List (Block frame α) :=
  blocks.filter Block.hasElements

end TensorRewrite.Theory.Concatenation
