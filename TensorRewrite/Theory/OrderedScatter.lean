module

public import TensorRewrite.Theory.LatticeIndex
public import TensorRewrite.Pilot.LinearIndexLemmas
public import TensorRewrite.Pilot.IndexMaps
public import Mathlib.Data.List.FinRange

/-! Ordered whole-state indexed updates and an independent full-window Scatter geometry. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.OrderedScatter

open Pilot

/-- One original update event; an absent address is explicitly dropped without calling
the reducer. -/
structure Entry {rank : Nat} (shape : Shape rank) (α : Type) where
  target : Option (Index shape)
  value : α

/-- Map only an event's whole scalar state, retaining its exact optional bounded address. -/
def Entry.mapValue {rank : Nat} {shape : Shape rank} {α β : Type} (convert : α → β)
    (entry : Entry shape α) : Entry shape β := ⟨entry.target, convert entry.value⟩

/-- Apply one event to the whole state at its actual bounded address. -/
def step {rank : Nat} {shape : Shape rank} {α : Type} (operation : α → α → α)
    (base : Tensor shape α) (entry : Entry shape α) : Tensor shape α :=
  match entry.target with
  | none => base
  | some target => fun index => if index = target then operation (base index) entry.value
      else base index

/-- Process the original event order, including duplicate and dropped addresses. -/
def run {rank : Nat} {shape : Shape rank} {α : Type} (operation : α → α → α)
    (base : Tensor shape α) (entries : List (Entry shape α)) : Tensor shape α :=
  entries.foldl (step operation) base

/-- Retain the original ordered values at one queried address; no commutation is performed. -/
def valuesAt {rank : Nat} {shape : Shape rank} {α : Type}
    (entries : List (Entry shape α)) (index : Index shape) : List α :=
  entries.filterMap fun entry => if entry.target = some index then some entry.value else none

/-- Full-rank update windows with a batch tensor and an explicit injective signed index-axis map.
Omitted input axes have start zero. Bounds are tested per element, without clamping. -/
structure Plan (rank batchRank indexSize : Nat) where
  operandShape : Shape rank
  batchShape : Shape batchRank
  windowShape : Shape rank
  indexAxes : IndexMaps.BroadcastAxes indexSize rank
  injective : Function.Injective indexAxes.decode

/-- Find the actual vector component addressing an operand axis; omitted axes start at zero. -/
def offset {rank batchRank indexSize : Nat} (plan : Plan rank batchRank indexSize)
    (indices : Tensor plan.batchShape (Fin indexSize → Int)) (batch : Index plan.batchShape)
    (axis : Fin rank) : Int :=
  match (List.finRange indexSize).find?
      (fun component => plan.indexAxes.decode component = axis) with
  | none => 0
  | some component => indices batch component

/-- Decode the actual index-vector offset plus window coordinate, dropping out-of-bounds
elements. -/
def target? {rank batchRank indexSize : Nat} (plan : Plan rank batchRank indexSize)
    (indices : Tensor plan.batchShape (Fin indexSize → Int)) (batch : Index plan.batchShape)
    (window : Index plan.windowShape) : Option (Index plan.operandShape) :=
  LatticeIndex.assemble? fun axis => LatticeIndex.decode? (plan.operandShape axis) 1 (by decide)
    (offset plan indices batch axis + (window axis).val)

/-- Build actual events in batch-major/window-major order from independently bounded coordinates. -/
def entries {rank batchRank indexSize : Nat} {α : Type}
    (plan : Plan rank batchRank indexSize) (indices : Tensor plan.batchShape (Fin indexSize → Int))
    (updates : Tensor plan.batchShape (Tensor plan.windowShape α)) :
    List (Entry plan.operandShape α) :=
  (List.finRange (LinearIndex.elementCount plan.batchShape)).flatMap fun batchPosition =>
    let batch := LinearIndex.delinearize plan.batchShape batchPosition
    (List.finRange (LinearIndex.elementCount plan.windowShape)).map fun windowPosition =>
      let window := LinearIndex.delinearize plan.windowShape windowPosition
      ⟨target? plan indices batch window, updates batch window⟩

/-- The actual declared Scatter profile; all reducers retain their whole coupled scalar state. -/
def scatter {rank batchRank indexSize : Nat} {α : Type} (plan : Plan rank batchRank indexSize)
    (operation : α → α → α) (base : Tensor plan.operandShape α)
    (indices : Tensor plan.batchShape (Fin indexSize → Int))
    (updates : Tensor plan.batchShape (Tensor plan.windowShape α)) : Tensor plan.operandShape α :=
  run operation base (entries plan indices updates)

/-- An empty index vector and scalar batch select a full zero-offset window on the operand. -/
def fullWindowPlan {rank : Nat} (shape : Shape rank) : Plan rank 0 0 where
  operandShape := shape
  batchShape := Fin.elim0
  windowShape := shape
  indexAxes := ⟨#v[], fun axis => Fin.elim0 axis⟩
  injective := fun axis => Fin.elim0 axis

end TensorRewrite.Theory.OrderedScatter
