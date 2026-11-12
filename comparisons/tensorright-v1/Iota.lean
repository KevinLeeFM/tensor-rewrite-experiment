module

public import TensorRewrite.Pilot.IndexMaps
public import TensorRewrite.Pilot.Indexing

/-! Paper-era integer Iota rules, interpreted as bounded coordinates. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Iota

open Pilot

/-- The mathematical Iota reads one selected bounded coordinate as an integer. -/
def tensor {rank : Nat} (shape : Shape rank) (axis : Fin rank) : Tensor shape Int :=
  fun index => (index axis).val

/-- `iota/rule01`: a unit-sized Iota axis contains only zero. -/
theorem unit_axis {rank : Nat} {shape : Shape rank} (axis : Fin rank)
    (unit : shape axis = 1) : tensor shape axis = Tensor.constant 0 := by
  funext index
  have bounded := (index axis).isLt
  have zero : (index axis).val = 0 := by omega
  simp [tensor, Tensor.constant, zero]

/-- `broadcast/rule07`: actual Broadcast preserves the selected Iota coordinate. -/
theorem broadcast {smallRank rank : Nat} {smallShape : Shape smallRank} {shape : Shape rank}
    (axes : IndexMaps.BroadcastAxes smallRank rank)
    (extents : ∀ axis, smallShape axis = shape (axes.decode axis)) (axis : Fin smallRank) :
    Tensor.reindex (IndexMaps.broadcastIndex axes extents) (tensor smallShape axis) =
      tensor shape (axes.decode axis) := by
  funext index
  rfl

/-- Compose the actual signed Broadcast axis maps by decoding both and re-encoding. -/
def composeAxes {smallRank middleRank rank : Nat}
    (first : IndexMaps.BroadcastAxes smallRank middleRank)
    (second : IndexMaps.BroadcastAxes middleRank rank) :
    IndexMaps.BroadcastAxes smallRank rank where
  values := Vector.ofFn fun axis => ((second.decode (first.decode axis)).val : Int)
  valid axis := by
    simp only [Fin.getElem_fin, Vector.getElem_ofFn]
    have bound := (second.decode (first.decode axis)).isLt
    omega

/-- Decoding the constructed signed map gives the composition of the original maps. -/
theorem composeAxes_decode {smallRank middleRank rank : Nat}
    (first : IndexMaps.BroadcastAxes smallRank middleRank)
    (second : IndexMaps.BroadcastAxes middleRank rank) (axis : Fin smallRank) :
    (composeAxes first second).decode axis = second.decode (first.decode axis) := by
  apply Fin.ext
  have nonnegative := (second.valid (first.decode axis)).1
  simp only [IndexMaps.BroadcastAxes.decode] at nonnegative
  simp [composeAxes, IndexMaps.BroadcastAxes.decode, Fin.getElem_fin, Vector.getElem_ofFn] <;>
    omega

/-- Original extent equalities imply the composed output extent equality. -/
theorem composedExtents {smallRank middleRank rank : Nat}
    {smallShape : Shape smallRank} {middleShape : Shape middleRank} {shape : Shape rank}
    (first : IndexMaps.BroadcastAxes smallRank middleRank)
    (second : IndexMaps.BroadcastAxes middleRank rank)
    (firstExtents : ∀ axis, smallShape axis = middleShape (first.decode axis))
    (secondExtents : ∀ axis, middleShape axis = shape (second.decode axis)) :
    ∀ axis, smallShape axis = shape ((composeAxes first second).decode axis) := by
  intro axis
  rw [composeAxes_decode]
  exact (firstExtents axis).trans (secondExtents (first.decode axis))

/-- `broadcast/rule08`: two actual Broadcast maps compose to their derived axis map. -/
theorem broadcast_composition {α : Type} {smallRank middleRank rank : Nat}
    {smallShape : Shape smallRank} {middleShape : Shape middleRank} {shape : Shape rank}
    (first : IndexMaps.BroadcastAxes smallRank middleRank)
    (second : IndexMaps.BroadcastAxes middleRank rank)
    (firstExtents : ∀ axis, smallShape axis = middleShape (first.decode axis))
    (secondExtents : ∀ axis, middleShape axis = shape (second.decode axis))
    (input : Tensor smallShape α) :
    Tensor.reindex (IndexMaps.broadcastIndex second secondExtents)
        (Tensor.reindex (IndexMaps.broadcastIndex first firstExtents) input) =
      Tensor.reindex (IndexMaps.broadcastIndex (composeAxes first second)
        (composedExtents first second firstExtents secondExtents)) input := by
  funext index
  apply congrArg input
  funext axis
  apply Fin.ext
  change (index (second.decode (first.decode axis))).val =
    (index ((composeAxes first second).decode axis)).val
  rw [composeAxes_decode]

#print axioms unit_axis
#print axioms broadcast
#print axioms broadcast_composition

end TensorRewrite.PaperComparison.Iota
