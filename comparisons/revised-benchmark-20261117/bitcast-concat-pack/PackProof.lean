module
public import PackSpec

public section
set_option autoImplicit false
namespace RevisedBenchmark.BitcastConcat
open TensorRewrite.Theory.BitPacking

private theorem concat_inverse {α β : Type} (f : α → β) (g : β → α)
    (inv : ∀ x, g (f x) = x) (last : List Nat) : Sandwich f g last := by
  intro pre post first rest
  dsimp only
  constructor
  · simp [shape, change, List.map_map, Function.comp_def]
  · intro p s
    simp [line, change, List.map_flatMap, List.flatMap_map, List.map_ofFn,
      Function.comp_def, inv]

private theorem pack_split (k w : Nat) (o : Order) (x : BitVec (k * w)) :
    pack k w o (split k w o x) = x := by
  unfold pack split
  rw [repack_compose, repack_refl]

private theorem split_pack (k w : Nat) (o : Order) (x : Words k w) :
    split k w o (pack k w o x) = x := by
  unfold split pack
  have single (v : Words 1 (k * w)) : (fun _ : Fin 1 => v 0) = v := by
    funext i
    exact congrArg v (Subsingleton.elim _ _)
  rw [single, repack_compose, repack_refl]

/-- Removing the two conversions around concatenation preserves shape and every raw bit. -/
theorem verified : Goal := by
  constructor
  · intro w _ o
    exact concat_inverse _ _ (fun x => by simp [same, repack_refl]) []
  · intro k w _ _ o
    exact ⟨concat_inverse _ _ (pack_split k w o) [],
      concat_inverse _ _ (split_pack k w o) [k]⟩

end RevisedBenchmark.BitcastConcat
