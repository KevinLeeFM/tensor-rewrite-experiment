module
public import TensorRewrite.Pilot.IndexMaps
public import TensorRewrite.Pilot.Reshape
public import TensorRewrite.Pilot.LinearIndexLemmas

@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.BroadcastReshapeSquare
open TensorRewrite.Pilot

/-- Square input and output, with equal static element counts definitionally. -/
def square (n : Nat) : Shape 2 := fun _ => n

/-- Nondecreasing repeated dimensions, permitted by the logical projection type. -/
def duplicate : IndexMaps.BroadcastAxes 2 2 := ⟨#[0,0].toVector, by decide⟩

/-- The existing Broadcast projection applied to every output coordinate. -/
def projected {n : Nat} {α : Type} (x : Tensor (square n) α) : Tensor (square n) α :=
  fun j => x (IndexMaps.broadcastIndex duplicate (fun _ => rfl) j)

/-- Value equality for every tensor, including nonconstant tensors. -/
def Agreement (n : Nat) : Prop :=
  ∀ (α : Type) (x : Tensor (square n) α), projected x = Reshape.reshapeTensor x (square n) rfl

/-- Exact boundary for this repeated-axis family. -/
def Target : Prop := ∀ n, Agreement n ↔ n ≤ 1
end RevisedBenchmark.BroadcastReshapeSquare
