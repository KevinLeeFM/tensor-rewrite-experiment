module
public import OrderedProof
public import PaperIota
public import ElementCount
public import TensorRewrite.Pilot.ReshapeLemmas
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.BroadcastUnits
open TensorRewrite.Pilot TensorRewrite.PaperComparison.Iota
/-- Surviving positions in original dimension order. -/
def positions {n : Nat} (keep : Fin n → Bool) := (List.finRange n).filter keep
/-- Supply the actual signed axis vector indexing surviving positions. -/
def kept {n : Nat} (keep : Fin n → Bool) : IndexMaps.BroadcastAxes (positions keep).length n where
  values := Vector.ofFn fun i => ((positions keep)[i].val : Int)
  valid i := by
    simp only [Fin.getElem_fin, Vector.getElem_ofFn]
    have := ((positions keep)[i]).isLt
    omega
/-- The shape retained by the selected dimension list. -/
def keptShape {n : Nat} (s : Shape n) (keep : Fin n → Bool) : Shape (positions keep).length :=
  fun i => s ((kept keep).decode i)
/-- Reshape inserts the positions omitted by the supplied descriptor; broadcast then elides it. -/
def Inserted : Prop := ∀ {m n : Nat} (s : Shape m) (t : Shape n) (keep : Fin m → Bool)
    (outer : IndexMaps.BroadcastAxes m n) (h : ∀ i, s i = t (outer.decode i))
    (eq : LinearIndex.elementCount (keptShape s keep) = LinearIndex.elementCount s)
    (α : Type) (x : Tensor (keptShape s keep) α),
    Tensor.reindex (IndexMaps.broadcastIndex outer h) (Reshape.reshapeTensor x s eq) =
    Tensor.reindex (IndexMaps.broadcastIndex (composeAxes (kept keep) outer)
      (composedExtents (kept keep) outer (fun i => rfl) h)) x
/-- Compute the actual nonunit filter, derive the reshape count, and compare both output tensors. -/
def Dropped : Prop := ∀ {m n : Nat} (s : Shape m) (t : Shape n)
    (outer : IndexMaps.BroadcastAxes m n) (h : ∀ i, s i = t (outer.decode i))
    (α : Type) (x : Tensor s α),
    let keep := fun i => decide (s i ≠ 1)
    ∃ eq : LinearIndex.elementCount s = LinearIndex.elementCount (keptShape s keep),
      Tensor.reindex (IndexMaps.broadcastIndex outer h) x =
      Tensor.reindex (IndexMaps.broadcastIndex (composeAxes (kept keep) outer)
        (composedExtents (kept keep) outer (fun i => rfl) h)) (Reshape.reshapeTensor x _ eq)
end RevisedBenchmark.BroadcastUnits
