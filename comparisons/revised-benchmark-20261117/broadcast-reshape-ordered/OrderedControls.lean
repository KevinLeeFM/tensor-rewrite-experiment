module
public import OrderedProof
public section
set_option autoImplicit false
namespace RevisedBenchmark.BroadcastOrdered
open TensorRewrite.Pilot

private def s : Shape 2 := fun a => #[2,3].toVector[a]
private def t : Shape 4 := fun a => #[1,2,1,3].toVector[a]
private def axes : IndexMaps.BroadcastAxes 2 4 := ⟨#[1,3].toVector, by decide⟩
private theorem matchDim : ∀ a, s a = t (axes.decode a) := by decide
private def w : Index t := fun a => ⟨t a - 1, by revert a; decide⟩
private def x : Tensor s Nat := fun i => 10 * (i 0).val + (i 1).val
example : (fun j => x (IndexMaps.broadcastIndex axes matchDim j)) =
    Reshape.reshapeTensor x t rfl := orderedReshape s t axes (by decide) matchDim rfl Nat x
example : x (IndexMaps.broadcastIndex axes matchDim w) = 12 := rfl
example : Reshape.reshapeTensor x t rfl w = 12 := rfl
example : Reshape.reshapeTensor x t rfl w ≠ 0 := by decide

private def es : Shape 1 := fun _ => 0
private def et : Shape 2 := fun a => #[5,0].toVector[a]
private def ea : IndexMaps.BroadcastAxes 1 2 := ⟨#[1].toVector, by decide⟩
private theorem em : ∀ a, es a = et (ea.decode a) := by decide
/-- The skipped extent is five; equal zero counts permit this instance. -/
example (v : Tensor es Nat) : (fun j => v (IndexMaps.broadcastIndex ea em j)) =
    Reshape.reshapeTensor v et rfl := orderedReshape es et ea (by decide) em rfl Nat v

private def noAxes : IndexMaps.BroadcastAxes 0 0 := ⟨#[].toVector, by decide⟩
private def scalar : Shape 0 := Fin.elim0
example (v : Tensor scalar Nat) :
    (fun j => v (IndexMaps.broadcastIndex noAxes (fun a => Fin.elim0 a) j)) =
    Reshape.reshapeTensor v scalar rfl :=
  orderedReshape scalar scalar noAxes (by decide) (fun a => Fin.elim0 a) rfl Nat v
end RevisedBenchmark.BroadcastOrdered
