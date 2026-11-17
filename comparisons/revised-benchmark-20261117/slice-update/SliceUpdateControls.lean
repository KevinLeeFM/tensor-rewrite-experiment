module
import SliceUpdateProof
set_option autoImplicit false
open TensorRewrite.Pilot TensorRewrite.Theory.DynamicUpdate SliceUpdate
private abbrev sh (n : Nat) : Shape 1 := fun _ => n
private def w (z : Int) : Window (sh 9) (sh 5) := ⟨fun _ => z, by decide⟩
example : (w (-17)).start 0 = 0 ∧ (w 51).start 0 = 4 := by decide
private def ax : Fin 1 → SliceShape.Axis := fun _ => ⟨5, 9, 2⟩
private theorem valid : ∀ d, SliceShape.IsWellFormed (sh 9 d) (sh 2 d) (ax d) := by decide
private def readAt (i : Index (sh 2)) :=
  (w 51).update (fun _ => 99) (fun j => (j 0).val) (IndexMaps.sliceIndex ax valid i)
example : readAt (fun _ => 0) = 1 ∧ readAt (fun _ => 1) = 3 := by decide
-- Dropping the stride would read 2 at the second position.
example : readAt (fun _ => 1) ≠ 2 := by decide
example : ¬ SliceShape.IsWellFormed 5 2 (translate ⟨3, 7, 2⟩ 4) := by decide
example : SliceShape.IsWellFormed 5 0 (translate ⟨9, 9, 2⟩ 4) := by decide
example : ∀ (base : Tensor (sh 9) Nat) (upd : Tensor (sh 5) Nat),
    (fun i => (w (-17)).update base upd
      (IndexMaps.sliceIndex (fun _ => ⟨0, 5, 1⟩)
        (show ∀ d, SliceShape.IsWellFormed (sh 9 d) (sh 5 d) ⟨0, 5, 1⟩ by decide) i)) = upd :=
  exactMatch (w (-17)) _ _ (by decide)
