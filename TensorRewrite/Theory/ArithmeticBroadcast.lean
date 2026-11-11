module

public import TensorRewrite.Theory.ArithmeticFamilyProof
public import TensorRewrite.Pilot.OperandOrderLemmas

/-! Actual bounded Broadcast graphs for exact arithmetic constant rebuilding and factoring. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ArithmeticFamily

open Pilot

/-- Subtraction of an actual bounded Broadcast equals Add with the small operand negated before
Broadcast; the output/input ranks and extents remain arbitrary. -/
theorem subtract_broadcast {α : Type} [CommRing α] {smallRank rank : Nat}
    {smallShape : Shape smallRank} {shape : Shape rank}
    (axes : IndexMaps.BroadcastAxes smallRank rank)
    (extents : ∀ axis, smallShape axis = shape (axes.decode axis))
    (input : Tensor shape α) (small : Tensor smallShape α) :
    Tensor.map₂ (· - ·) input (Tensor.reindex (IndexMaps.broadcastIndex axes extents) small) =
      Tensor.map₂ (· + ·) input
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents) (Tensor.map (- ·) small)) := by
  funext index
  simp [Tensor.map₂, Tensor.map, Tensor.reindex, sub_eq_add_neg]

/-- The actual small-tensor sum may be rebuilt before Broadcast under exact ring semantics. -/
theorem add_broadcast_constants {α : Type} [CommRing α] {smallRank rank : Nat}
    {smallShape : Shape smallRank} {shape : Shape rank}
    (axes : IndexMaps.BroadcastAxes smallRank rank)
    (extents : ∀ axis, smallShape axis = shape (axes.decode axis))
    (inner outer : Bool) (input : Tensor shape α) (first second : Tensor smallShape α) :
    OperandOrder.map₂ (· + ·) outer (OperandOrder.map₂ (· + ·) inner input
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents) first))
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents) second) =
      Tensor.map₂ (· + ·) input (Tensor.reindex (IndexMaps.broadcastIndex axes extents)
        (Tensor.map₂ (· + ·) first second)) := by
  rw [OperandOrder.map₂_eq (· + ·) add_comm, OperandOrder.map₂_eq (· + ·) add_comm]
  funext index
  simp [Tensor.map₂, Tensor.reindex, add_assoc]

/-- Rebuild the actual small sum in Broadcast(c1)-x+Broadcast(c2), preserving subtraction order. -/
theorem subtract_add_broadcast_constants {α : Type} [CommRing α] {smallRank rank : Nat}
    {smallShape : Shape smallRank} {shape : Shape rank}
    (axes : IndexMaps.BroadcastAxes smallRank rank)
    (extents : ∀ axis, smallShape axis = shape (axes.decode axis))
    (outer : Bool) (input : Tensor shape α) (first second : Tensor smallShape α) :
    OperandOrder.map₂ (· + ·) outer (Tensor.map₂ (· - ·)
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents) first) input)
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents) second) =
      Tensor.map₂ (· - ·) (Tensor.reindex (IndexMaps.broadcastIndex axes extents)
        (Tensor.map₂ (· + ·) first second)) input := by
  rw [OperandOrder.map₂_eq (· + ·) add_comm]
  funext index
  simp only [Tensor.map₂, Tensor.reindex]
  ring

/-- All matched inner/outer product orders allow actual small-tensor product rebuilding. -/
theorem multiply_broadcast_constants {α : Type} [CommRing α] {smallRank rank : Nat}
    {smallShape : Shape smallRank} {shape : Shape rank}
    (axes : IndexMaps.BroadcastAxes smallRank rank)
    (extents : ∀ axis, smallShape axis = shape (axes.decode axis)) (inner outer : Bool)
    (input : Tensor shape α) (first second : Tensor smallShape α) :
    OperandOrder.map₂ (· * ·) outer (OperandOrder.map₂ (· * ·) inner input
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents) first))
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents) second) =
      Tensor.map₂ (· * ·) input (Tensor.reindex (IndexMaps.broadcastIndex axes extents)
        (Tensor.map₂ (· * ·) first second)) := by
  rw [OperandOrder.map₂_eq (· * ·) mul_comm, OperandOrder.map₂_eq (· * ·) mul_comm]
  funext index
  simp [Tensor.map₂, Tensor.reindex, mul_assoc]

/-- A uniform scalar factor can move inside the actual Broadcast graph in either matched order. -/
theorem broadcast_uniform_factor {α : Type} [CommRing α] {smallRank rank : Nat}
    {smallShape : Shape smallRank} {shape : Shape rank}
    (axes : IndexMaps.BroadcastAxes smallRank rank)
    (extents : ∀ axis, smallShape axis = shape (axes.decode axis)) (inner outer : Bool)
    (input : Tensor shape α) (small : Tensor smallShape α) (factor : α) :
    OperandOrder.map₂ (· * ·) outer
        (OperandOrder.map₂ (· * ·) inner input (Tensor.constant factor))
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents) small) =
      Tensor.map₂ (· * ·) input (Tensor.reindex (IndexMaps.broadcastIndex axes extents)
        (Tensor.map₂ (· * ·) small (Tensor.constant factor))) := by
  rw [OperandOrder.map₂_eq (· * ·) mul_comm, OperandOrder.map₂_eq (· * ·) mul_comm]
  funext index
  simp only [Tensor.map₂, Tensor.reindex, Tensor.constant]
  ring

end TensorRewrite.Theory.ArithmeticFamily
