import SwapCopyProof
set_option autoImplicit false
namespace RevisedBenchmark.SwapCopyBitcast
open CopyChain
private def seq (i : Fin 4) := i.val
-- Each success requires a crossed physical axis correspondence between c and b.
private def run (s c b d : OrderTile) := (emitted (n:=2) (by decide) s c b d seq).map List.ofFn
private def obs (s c b d : OrderTile) := List.ofFn (old (n:=2) (by decide) s c b d seq)
private def r : OrderTile := ⟨false,false⟩
private def column : OrderTile := ⟨true,false⟩
private def r2 : OrderTile := ⟨false,true⟩
example : run r r column r = some [0,2,1,3] ∧ obs r r column r = [0,2,1,3] := by decide
example : valid column r2 = false ∧ valid column r = true ∧ valid r r = true ∧
    run r2 r column r = some [0,2,1,3] ∧ obs r2 r column r = [0,2,1,3] := by decide
example : run r2 r column r2 = none := by decide
example : List.ofFn (copy (view (n:=2) (by decide) false) (view (n:=2) (by decide) false) seq)
    ≠ obs r2 r column r := by decide
example : tiledOffset 6 4 5 true = 29 ∧ tiledOffset 6 4 5 false = 29 := by decide
-- Both original copies reorder physical values. Their two swaps cancel.
example : run column r column r = some [0,1,2,3] ∧
    obs column r column r = [0,1,2,3] := by decide
example : run ⟨true,true⟩ r column r = some [0,1,2,3] ∧
    obs ⟨true,true⟩ r column r = [0,1,2,3] := by decide
#check (verified : Goal)
end RevisedBenchmark.SwapCopyBitcast
