module
public import TensorRewrite.Pilot.IndexMapLemmas
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceBroadcast
open TensorRewrite.Pilot
/-- The source Broadcast followed by the source Slice, with verified static attributes. -/
structure Plan (m n : Nat) where
  operand : Shape m
  broadcast : Shape n
  result : Shape n
  dims : IndexMaps.BroadcastAxes m n
  matched : ∀ i, operand i = broadcast (dims.decode i)
  attrs : Fin n → SliceShape.Axis
  valid : ∀ k, SliceShape.IsWellFormed (broadcast k) (result k) (attrs k)
variable {m n : Nat}
def Plan.project (p : Plan m n) (i : Fin m) := p.attrs (p.dims.decode i)
/-- Source integer ceiling formula on the projected starts, limits and strides. -/
def Plan.inner (p : Plan m n) : Shape m := fun i => (p.project i).elementCount.toNat
def Plan.original (p : Plan m n) {α : Type} (x : Tensor p.operand α) : Tensor p.result α :=
  fun j => x (IndexMaps.broadcastIndex p.dims p.matched (IndexMaps.sliceIndex p.attrs p.valid j))
/-- Source returns a Broadcast of the sliced operand. Both newly needed validity certificates
and the whole-tensor equation must be established. -/
def Sink : Prop := ∀ {m n} (p : Plan m n),
  ∃ (v : ∀ i, SliceShape.IsWellFormed (p.operand i) (p.inner i) (p.project i))
    (e : ∀ i, p.inner i = p.result (p.dims.decode i)),
    ∀ (α : Type) (x : Tensor p.operand α),
      p.original x = fun j => x (IndexMaps.sliceIndex p.project v (IndexMaps.broadcastIndex p.dims e j))
/-- The earlier branch's explicit source guards on every mapped output dimension. -/
def Only : Prop := ∀ {m n} (p : Plan m n),
  (∀ i, (p.project i).start = 0 ∧ (p.project i).stride = 1 ∧
    (p.project i).limit = p.broadcast (p.dims.decode i)) →
  ∃ (e : ∀ i, p.operand i = p.result (p.dims.decode i)),
    ∀ (α : Type) (x : Tensor p.operand α),
      p.original x = fun j => x (IndexMaps.broadcastIndex p.dims e j)
end RevisedBenchmark.SliceBroadcast
