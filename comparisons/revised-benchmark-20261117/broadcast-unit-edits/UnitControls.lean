module
public import UnitProof
public section
set_option autoImplicit false
namespace RevisedBenchmark.BroadcastUnits
open TensorRewrite.Pilot TensorRewrite.PaperComparison.Iota
private def s : Shape 4 := fun i => #[1,2,1,2].toVector[i]
private def outer : IndexMaps.BroadcastAxes 4 4 := ⟨#[0,1,2,3].toVector, by decide⟩
private theorem matched : ∀ i, s i = s (outer.decode i) := by decide
private def keep (i : Fin 4) := decide (s i ≠ 1)
private def point : Index s := fun i => ⟨#[0,0,0,1].toVector[i], by revert i; decide⟩
private def small : Tensor (keptShape s keep) Nat := fun i => 10 * (i ⟨0, by decide⟩).val + (i ⟨1, by decide⟩).val
private def big : Tensor s Nat := fun i => 10 * (i 1).val + (i 3).val
private def wrong : IndexMaps.BroadcastAxes 2 4 := ⟨#[3,1].toVector, by decide⟩
private theorem wrongMatches : ∀ i, keptShape s keep i = s (wrong.decode i) := by decide

example : (positions keep).map Fin.val = [1,3] := rfl
example : (composeAxes (kept keep) outer).values = #[1,3].toVector := rfl
example : Tensor.reindex (IndexMaps.broadcastIndex outer matched)
    (Reshape.reshapeTensor small s rfl) point = 1 := rfl
example : Tensor.reindex (IndexMaps.broadcastIndex (composeAxes (kept keep) outer)
    (composedExtents _ _ (fun _ => rfl) matched)) small point = 1 := rfl
example : Tensor.reindex (IndexMaps.broadcastIndex outer matched) big point = 1 := rfl
example : Tensor.reindex (IndexMaps.broadcastIndex (composeAxes (kept keep) outer)
    (composedExtents _ _ (fun _ => rfl) matched)) (Reshape.reshapeTensor big _ rfl) point = 1 := rfl
example : Tensor.reindex (IndexMaps.broadcastIndex wrong wrongMatches) small point = 10 := rfl
example : Tensor.reindex (IndexMaps.broadcastIndex wrong wrongMatches)
    (Reshape.reshapeTensor big _ rfl) point ≠ 1 := by decide
private def zeroShape : Shape 3 := fun i => #[1,0,1].toVector[i]
example : (positions (fun i => decide (zeroShape i ≠ 1))).map Fin.val = [1] := rfl
example : LinearIndex.elementCount (keptShape zeroShape (fun i => decide (zeroShape i ≠ 1))) = 0 := rfl
example : (positions (fun _ : Fin 2 => false)).length = 0 := rfl
example : LinearIndex.elementCount (keptShape (fun _ : Fin 2 => 1) (fun _ => false)) = 1 := rfl
/-- An insertion descriptor can keep an existing unit axis. -/
private def descriptor (i : Fin 4) := decide (i.val ≠ 2)
example : (positions descriptor).map Fin.val = [0,1,3] := rfl
example : (composeAxes (kept descriptor) outer).values = #[0,1,3].toVector := rfl
example (x : Tensor (keptShape s descriptor) Nat) :
    Tensor.reindex (IndexMaps.broadcastIndex outer matched) (Reshape.reshapeTensor x s rfl) =
    Tensor.reindex (IndexMaps.broadcastIndex (composeAxes (kept descriptor) outer)
      (composedExtents _ _ (fun _ => rfl) matched)) x := inserted s s descriptor outer matched rfl Nat x
end RevisedBenchmark.BroadcastUnits
