module

public import TensorRewrite.Pilot.ModularArithmetic
public import TensorRewrite.Pilot.OperandOrderLemmas
public import TensorRewrite.Pilot.IndexMaps

/-! Value bridges for captured AnyOrder orientations and concrete Broadcast axes.
C++ matcher binding, constant evaluation and graph mutation remain separate. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.ModularArithmetic

open Tensor

variable {rank : Nat} {shape : Shape rank} {width : Nat}

/-- Gather a shared factor in every pair of captured Multiply operand orders. -/
theorem factor_any_order (lhsOrder rhsOrder : Bool) (x y c : Tensor shape (BitVec width)) :
    map₂ (· + ·) (OperandOrder.map₂ (· * ·) lhsOrder x c)
      (OperandOrder.map₂ (· * ·) rhsOrder y c) = map₂ (· * ·) (map₂ (· + ·) x y) c := by
  simp only [OperandOrder.map₂_eq _ BitVec.mul_comm]
  exact factor_right x y c

/-- Gather constants across both captured Multiply operand orders. -/
theorem mul_assoc_any_order (innerOrder outerOrder : Bool)
    (x c1 c2 : Tensor shape (BitVec width)) :
    OperandOrder.map₂ (· * ·) outerOrder (OperandOrder.map₂ (· * ·) innerOrder x c1) c2 =
      map₂ (· * ·) x (map₂ (· * ·) c1 c2) := by
  simp only [OperandOrder.map₂_eq _ BitVec.mul_comm]
  exact mul_assoc x c1 c2

/-- Regroup four factors in all eight nested Multiply orientations. -/
theorem four_factors_any_order (leftOrder rightOrder outerOrder : Bool)
    (x y c1 c2 : Tensor shape (BitVec width)) :
    OperandOrder.map₂ (· * ·) outerOrder (OperandOrder.map₂ (· * ·) leftOrder x c1)
      (OperandOrder.map₂ (· * ·) rightOrder y c2) =
      map₂ (· * ·) (map₂ (· * ·) x y) (map₂ (· * ·) c1 c2) := by
  simp only [OperandOrder.map₂_eq _ BitVec.mul_comm]
  exact four_factors x y c1 c2

section Broadcast

variable {smallRank : Nat} {smallShape : Shape smallRank}
  (axes : IndexMaps.BroadcastAxes smallRank rank)
  (extents : ∀ axis, smallShape axis = shape (axes.decode axis))

/-- Add reassociation preserves the concrete shared broadcast projection. -/
theorem add_broadcast_assoc (x : Tensor shape (BitVec width))
    (c1 c2 : Tensor smallShape (BitVec width)) :
    map₂ (· + ·) (map₂ (· + ·) x (reindex (IndexMaps.broadcastIndex axes extents) c1))
      (reindex (IndexMaps.broadcastIndex axes extents) c2) =
      map₂ (· + ·) x (reindex (IndexMaps.broadcastIndex axes extents) (map₂ (· + ·) c1 c2)) := by
  rw [Tensor.reindex_map₂]
  exact add_assoc x _ _

/-- Constant gathering across subtraction uses the same concrete broadcast axes. -/
theorem sub_add_broadcast (x : Tensor shape (BitVec width))
    (c1 c2 : Tensor smallShape (BitVec width)) :
    map₂ (· + ·) (map₂ (· - ·) (reindex (IndexMaps.broadcastIndex axes extents) c1) x)
      (reindex (IndexMaps.broadcastIndex axes extents) c2) =
      map₂ (· - ·) (reindex (IndexMaps.broadcastIndex axes extents) (map₂ (· + ·) c1 c2)) x := by
  rw [Tensor.reindex_map₂]
  exact sub_add_constant x (reindex (IndexMaps.broadcastIndex axes extents) c1)
    (reindex (IndexMaps.broadcastIndex axes extents) c2)

/-- Multiply reassociation preserves constant gathering through the same broadcast map. -/
theorem mul_broadcast_assoc (x : Tensor shape (BitVec width))
    (c1 c2 : Tensor smallShape (BitVec width)) :
    map₂ (· * ·) (map₂ (· * ·) x (reindex (IndexMaps.broadcastIndex axes extents) c1))
      (reindex (IndexMaps.broadcastIndex axes extents) c2) =
      map₂ (· * ·) x (reindex (IndexMaps.broadcastIndex axes extents) (map₂ (· * ·) c1 c2)) := by
  rw [Tensor.reindex_map₂]
  exact mul_assoc x _ _

/-- Move a scalar factor into a broadcast operand in all captured Multiply orders. -/
theorem broadcast_factor_any_order (innerOrder outerOrder : Bool)
    (x : Tensor shape (BitVec width)) (operand : Tensor smallShape (BitVec width))
    (scalar : BitVec width) :
    OperandOrder.map₂ (· * ·) outerOrder
      (OperandOrder.map₂ (· * ·) innerOrder x (constant scalar))
      (reindex (IndexMaps.broadcastIndex axes extents) operand) =
      map₂ (· * ·) x (reindex (IndexMaps.broadcastIndex axes extents)
        (map₂ (· * ·) operand (constant scalar))) := by
  simp only [OperandOrder.map₂_eq _ BitVec.mul_comm]
  rw [Tensor.reindex_map₂, Tensor.reindex_constant]
  funext index
  change (x index * scalar) * operand (IndexMaps.broadcastIndex axes extents index) =
    x index * (operand (IndexMaps.broadcastIndex axes extents index) * scalar)
  rw [BitVec.mul_assoc, BitVec.mul_comm scalar]

end Broadcast

end TensorRewrite.Pilot.ModularArithmetic
